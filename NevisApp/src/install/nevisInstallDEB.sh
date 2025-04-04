#!/bin/bash
APP_BASE_PATH="/nevis_app"

APP_NAME='nevis_app'
APP_VERSION='1.4.0'
APP_EXT='.deb'
APP_FULL_NAME="${APP_NAME}_${APP_VERSION}"

APP_SYMLINK_NAME="nevis_latest"
APP_SYMLINK_PATH="${APP_BASE_PATH}/${APP_SYMLINK_NAME}"

APP_ROLLBACK_BASE_PATH="TEMP"
APP_ROLLBACK_LOG="${APP_ROLLBACK_BASE_PATH}/rollback.log"

APP_BASE_PATH_INSTALL="/opt/nevis" 
APP_CONFIG_PATH="$APP_BASE_PATH_INSTALL/conf"

TIMESTAMP=$( date +%Y-%m-%d_%H-%M )

unknown_os ()
{
  echo "Sfortunatamente, la distribuzione e versione del tuo sistema operativo non sono supportati."
  exit 1
}

detect_os ()
{
  if [[ ( -z "${os}" ) && ( -z "${dist}" ) ]]; then
    # some systems dont have lsb-release yet have the lsb_release binary and
    # vice-versa
    if [ -e /etc/lsb-release ]; then
      . /etc/lsb-release

      if [ "${ID}" = "raspbian" ]; then
        os=${ID}
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      else
        os=${DISTRIB_ID}
        dist=${DISTRIB_CODENAME}

        if [ -z "$dist" ]; then
          dist=${DISTRIB_RELEASE}
        fi
      fi

    elif [ `which lsb_release 2>/dev/null` ]; then
      dist=`lsb_release -c | cut -f2`
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`

    elif [ -e /etc/debian_version ]; then
      # some Debians have jessie/sid in their /etc/debian_version
      # while others have '6.0.7'
      os=`cat /etc/issue | head -1 | awk '{ print tolower($1) }'`
      if grep -q '/' /etc/debian_version; then
        dist=`cut --delimiter='/' -f1 /etc/debian_version`
      else
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      fi

    else
      unknown_os
    fi
  fi

  if [ -z "$dist" ]; then
    unknown_os
  fi

  # rimuovo gli spazi dal nome del Sistema Operativo e Distribuzione
  os="${os// /}"
  dist="${dist// /}"

  echo "Verifica Sistema Operativo: $os/$dist."
  
  # Check Debian OS
  if [ "${os}" != "debian" ]; then
    unknown_os
  fi
  
}

detect_authorization()
{
	# ROOT checks
	if [ $(id -u) -ne 0 ]
	then
		echo "NeViS ha bisogno dei permessi di ROOT per essere eseguito!"
		exit 1
	fi
}

detect_previus_app(){
	#leggo output e lo inserisco in $APP_PREVIOUS_VERSION
	APP_PREVIOUS_VERSION=$(dpkg -l | awk '$2=="nevisapp" {print $3}')
	#Verifico la presenza del software e se il software e gia agiornato
	if [ -z "$APP_PREVIOUS_VERSION" ] || [ "$APP_PREVIOUS_VERSION" == "$APP_VERSION" ]; then
		echo "Aggiornamento interrotto. Non sono presenti versioni precedenti del software o hai gia installata un ultima versione.";
		#exit 1;
	fi
	#read APP_PREVIOUS_VERSION
	APP_PREVIOUS_FULL_NAME="${APP_NAME}_${APP_PREVIOUS_VERSION}"
}

rollback_install(){
	echo "Ripristino installazione in corso...";
	#leggo il file rollback.log ed eseguo tutti i comandi
	while read -r line 
	do 
	   #trap 'echo "# ${line}"' DEBUG
	   command ${line}
	done< "${APP_ROLLBACK_LOG}"
	echo "Ripristino completato!"
}

check_command(){
	#Verifico se nell'ultimo comando eseguito, errori exit 1
	if [[ $? > 0 ]]; then
		echo "[Errore] Installazione interrotta."
		cleanup
		rollback_install
		exit 1;
	fi
}

TOTAL=100
DELAY=0.25

PROGRESS=""

get_progress() {

    local perc dperc item total scale cols lines output
	local FB=2588

    cols=$(tput cols)

    item=$1
    shift
    total=$1

    perc="$(LANG=C printf "%d/%d\n" "$item" "$total" | bc --mathlib | tr -d '\\\n')"
	
    dperc="$(LANG=C printf "%f*100\n" "$perc" | bc --mathlib | tr -d '\\\n')"
	
	
    dperc="$(LANG=C printf "%0.2f" "$dperc")"


    PROGRESS=$(LANG=C printf "Caricamento %s%% (%d/%d)" "$dperc" "$item" "$total")
    cols="$(LANG=C printf "%d-%d\n" "$cols" "${#PROGRESS}" | bc | tr -d '\\\n')"

    width="$(LANG=C printf "%d*%0.2f\n" "$cols" "$perc" | bc --mathlib | tr -d '\\\n')"
    width="$(LANG=C printf "%0.0f" "$width")"

    output=
    while (( ${#output} < width )); do
		ouut2=$(printf "\\u$FB")
        output="${output}${ouut2}"
    done
	#42m GREEN Background
	#44m BLU BACKGROUND
	#49m BIANCO BACKGROUND
    PROGRESS=$(LANG=C printf "\033[44m%s\033[49m%s" "$PROGRESS" "$output")

}

update_progress() {
    local lines first_scrollable_line last_scrollable_line progress

    progress=$1
    lines=$(tput lines)
    first_scrollable_line=0
    last_scrollable_line=$(( lines - 1 ))

    # Scoot off the baseline, if we're there
    printf '\n'

    # Save our current cursor
    # (tput sc)
    printf '\033[s'

    # Make a scroll region that excludes the last line
    # ([using tput you don't have to subtract 1] tput csr $(tput lines) 0)
    printf '\033[%d;%dr' "$first_scrollable_line" "$last_scrollable_line"

    get_progress "$1" "$TOTAL"

    # Move cursor to last line, write stuff
    # (tput cup $(tput lines) 0)
    printf "\033[%d;0f\033[K%s" "$lines" "$PROGRESS"

    # Restore our cursor
    # (tput rc)
    printf '\033[u\033[1A'
}

cleanup() {
    local lines

    lines=$(tput lines)

    # Save our current cursor
    # (tput sc)
    printf '\033[s'

    # Clear the last line
    # (tput cup $(tput lines) 0; tput clear)
    printf "\033[%d;0f\033[K" "$lines"

    # Reset scroll region
    printf '\033[0;%dr' "$(tput lines)"

    # Restore our cursor
    # (tput rc)
    printf '\033[u\033[J'
}


# Start NeViS
main ()
{


	#i=0
    #while (( i < TOTAL )); do
        #update_progress "$i" "$TOTAL"
        #echo "$i -- This. Is Progress"
        #sleep "$DELAY"
        #(( i++ ))
    #done
	
	#detect_previus_app
	detect_os
	detect_authorization
	
	#declare -a packages=("apache2" "ffmpeg" "$APP_NAME");

	#for i in "${packages[@]}"; do
		#if ! dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -q "ok installed"; then
		#if [ $(dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			#echo "Il pacchetto << $i >> NON è aggiornato. Vuoi proseguire con l'aggiornamento? (S/n)";
			#read response
			#if [[ $response == [sS] ]]; then
			#if [ "$response" == "y" ] || [ "$response" == "Y" ]; then
				update_progress "71" "$TOTAL"
				echo "[#TEMP]"
				#creo la cartella temp
				mkdir -p "${APP_ROLLBACK_BASE_PATH}"
				#rm -f "${APP_ROLLBACK_LOG}"
				#touch "${APP_ROLLBACK_LOG}"
				echo "rm -Rf ${APP_ROLLBACK_BASE_PATH}" >> $APP_ROLLBACK_LOG
				check_command
				update_progress "72" "$TOTAL"
				
				#echo "[#BACKUP][INIT]"
				#Creo la cartella di backup se non esiste
				#echo "rm -Rf ${APP_BASE_PATH}/${APP_PREVIOUS_FULL_NAME}" >> $APP_ROLLBACK_LOG
				#mkdir -p "${APP_BASE_PATH}/${APP_PREVIOUS_FULL_NAME}"
				#check_command
				
				#Effettuo il backup dell'applicazione precedente (-pczf)
				#echo "rm -f ${APP_ROLLBACK_BASE_PATH}/${APP_PREVIOUS_FULL_NAME}.tar.gz" >> $APP_ROLLBACK_LOG			
				#tar zcvf "${APP_ROLLBACK_BASE_PATH}/${APP_PREVIOUS_FULL_NAME}.tar.gz" "${APP_BASE_PATH}/${APP_PREVIOUS_FULL_NAME}/" --exclude "/${APP_BASE_PATH}/${APP_PREVIOUS_FULL_NAME}/log" 
				#--exclude "/${APP_BASE_PATH}/${APP_PREVIOUS_FULL_NAME}/db"
				#check_command
				#update_progress "50" "$TOTAL"
				
				#creo la cartella della nuova versione
				#echo "rm -R ${APP_BASE_PATH}/${APP_FULL_NAME}" >> $APP_ROLLBACK_LOG
				#mkdir -p "${APP_BASE_PATH}/${APP_FULL_NAME}"
				#check_command
				
				#echo "[#cryptsetup luksOpen]"
				#echo -n "nevis" | cryptsetup luksOpen /dev/sda3 videocrypt && mount /dev/mapper/videocrypt /nevis
				
				echo "[#SETUP#][START] << $i >> ...";
				#Disinstallo l'App
				#apt-get --purge autoremove ${APP_NAME}
				#Installo l'App
				#dpkg -i "${APP_FULL_NAME}.deb" 2>&1 > "${APP_BASE_PATH}/${APP_FULL_NAME}/${APP_FULL_NAME}.log"
				dpkg -i "${APP_FULL_NAME}.deb"
				#check_command
				update_progress "73" "$TOTAL"
				
				echo "[#SYMLINK]"	
				#Rimuovo symlink
				rm -f "${APP_SYMLINK_PATH}"
				#Rinomino il symlink
				ln -sf "${APP_BASE_PATH}/${APP_FULL_NAME}" "${APP_SYMLINK_PATH}"
				update_progress "74" "$TOTAL"
				
				cp "/opt/nevis/conf/luks/partitions_conf.json" "${APP_SYMLINK_PATH}/conf/partitions_conf.json"
				
				#echo "[#BACKUP][MOVE]"
				#Crea cartella di Backup e sposta il backup al suo interno
				#mkdir -p "/${APP_BASE_PATH}/${APP_PREVIOUS_FULL_NAME}" && mv "${APP_ROLLBACK_BASE_PATH}/${APP_PREVIOUS_FULL_NAME}.tar.gz" $_
				#update_progress "90" "$TOTAL"
				
				update_progress "75" "$TOTAL"
				######################################
				echo "SERVICES NEVIS UPGRADE" >> $INSTALLER_LOG
				cp "${APP_CONFIG_PATH}/services/nevisus.service" "/etc/systemd/system/nevisus.service"
				chmod +x "/etc/systemd/system/nevisus.service"
				systemctl daemon-reload
				systemctl enable nevisus.service
				update_progress "76" "$TOTAL"
				
				######################################
				echo "[#PERMESSI]"
				update_progress "77" "$TOTAL"
				chown -Rf www-data:www-data "/nevis/public"
				chown -Rf www-data:www-data "${APP_BASE_PATH}"
				
				update_progress "78" "$TOTAL"
				chmod 755 -Rf "${APP_SYMLINK_PATH}/*"
				
				update_progress "79" "$TOTAL"
				
				######################################
				echo "[#NEVIS SERVICES]"
				update_progress "80" "$TOTAL"
				systemctl stop nevisus.service
				systemctl start nevisus.service
				
				update_progress "81" "$TOTAL"
				systemctl stop startstop.service
				systemctl start startstop.service
				
				update_progress "82" "$TOTAL"
				systemctl stop nevis.service
				systemctl start nevis.service
				
				update_progress "83" "$TOTAL"
				service cron stop
				service cron start
				
				update_progress "84" "$TOTAL"
				
				######################################
				echo "[#CLEAR]"
				#Cancello cartella TEMP
				rm -Rf "${APP_ROLLBACK_BASE_PATH}"
				update_progress "85" "$TOTAL"
				
				echo "[#SETUP#][END] Il pacchetto << $i >> installato."
				cleanup				
			#else
				#echo "Installazione << $i >> interrotta.";
				#cleanup
			#fi
		#else
			#echo "Pacchetto << $i >> installato sul sistema.";
		#fi
	#done
}

main