#!/bin/bash
APP_BASE_PATH_SRC="/opt/src/nevis"
APP_BASE_PATH="/opt/nevis" 
APP_BASE_PATH_INSTALLER="/opt/installer"
#REPOSITORY
APP_REPOSITORY_PATH="$APP_BASE_PATH/repo"
APP_REPOSITORY_PACK="_opt_nevis_repo_Packages"

APP_CONFIG_PATH="$APP_BASE_PATH/conf"
INSTALLER_LOG="installer.log"

#USERS
ROOT_USER="root"
TOMCAT_USER="tomcat"
NEVIS_USER="nevis"
NEVIS_PASS="+BB9AF2Jw>YHRxv;tuWTUX8ecd2HGHoT"
POLFER_USER="polfer"
#ROOTPASS
RTPD="x533qYFhk0"

#LUKS
LUKSUSERSLIST="$ROOT_USER~$NEVIS_USER~$POLFER_USER"
LUKSPASSWORD="$RTPD"
LUKSROOTDEVICE="/dev/sda3"
LUKSMAPPER="/dev/mapper/videocrypt"
LUKSMOUNTPATH="/nevis"

#RAMDISK
RAMDISKPATH="/mnt/ramdisk"
RAMDISKSIZE="1G"

TIMESTAMP=$( date +%Y-%m-%d_%H-%M )

export PIP_FORMAT=columns

unknown_os(){
  echo "Sfortunatamente, la distribuzione e versione del tuo sistema operativo non sono supportati."
  exit 1
}

detect_os(){
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

detect_authorization(){
	# ROOT checks
	if [ $(id -u) -ne 0 ]
	then
		echo "NeViS ha bisogno dei permessi di ROOT per essere eseguito."
		exit 1
	fi
}

check_command(){
	#Verifico se nell'ultimo comando eseguito, errori exit 1
	if [[ $? > 0 ]]; then
		echo "Errore durante il processo di installazione."
		cleanup
		exit 1;
	fi
}

TOTAL=100
DELAY=0.25

PROGRESS=""

get_progress(){

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

update_progress(){
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

cleanup(){
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

user_exist(){
   awk -F":" '{ print $1 }' /etc/passwd |grep -x $1
   return $?
}

java_exist(){
	#version="java -version 2>&1 >/dev/null |grep 'java version' |awk '{print $3}' > /dev/null"
	version=$(java -version 2>&1 >/dev/null |grep 'java version' |awk '{print $3}')
	return $?
}
	
service_exist(){
	#service --status-all |grep $1 |awk '{print $4}'
	#ps cax | grep $1 > /dev/null
	ps auxw | grep -P '\b'$1'(?!-)\b' >/dev/null
	return $?
}

cryptsetup_exist(){
	cryptsetup status $1 |grep -iw 'active' > /dev/null
	return $?
}

addtocrontab () {
	local frequency=$1
	local command=$2
	local job="$frequency $command"
	cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -
}

deviceIsMounted(){
    lsblk |grep -q "$1"
	return $?
}

textinfile_exist(){
	grep -R "$1" "$2" > /dev/null
	return $?
}

pause(){
   read -p "$*"
}

# Start NeViS
main ()
{
	detect_os
	detect_authorization
	
#if [ ]; then 	
	#echo "Installazione dei Paccheti di Terze Parti di NeViS Surveillance. Vuoi proseguire?";
	#read response
	#if [[ $response == [sS] ]]; then			
		echo "==== START INSTALL ====" >> $INSTALLER_LOG
		update_progress "0" "$TOTAL"
		#echo "Create build from: ${APP_BASE_PATH_SRC}" >> $INSTALLER_LOG		
		#tar -zcvf "installerdebianpack.tar.gz" -C "${APP_BASE_PATH_SRC}" .
		
		######################################
		echo "FOLDER CREATE : ${APP_BASE_PATH}" >> $INSTALLER_LOG
		mkdir -p "${APP_BASE_PATH}"
		update_progress "1" "$TOTAL"

		######################################
		echo "UNPACKING : installerdebianpack.tar.gz" >> $INSTALLER_LOG
		tar -zxvf "./installerdebianpack.tar.gz" -C "${APP_BASE_PATH}" >> $INSTALLER_LOG
		#check_command
		update_progress "5" "$TOTAL"
		
		######################################
		echo "SOURCESLIST: backup" >> $INSTALLER_LOG
		cp "/etc/apt/sources.list" "/etc/apt/sources-backup.list"
		update_progress "6" "$TOTAL"
		
		######################################
		echo "SOURCESLIST: creation" >> $INSTALLER_LOG
		rm -f "/etc/apt/sources.list"
		echo "deb file://${APP_REPOSITORY_PATH} /" >> "/etc/apt/sources.list"
		#cp "${APP_REPOSITORY_PATH}/sources.list" "/etc/apt/sources.list"
		update_progress "7" "$TOTAL"

		
		######################################
		echo "LOCAL REPOSITORY UPDATE" >> $INSTALLER_LOG
		apt-get update >> $INSTALLER_LOG
		update_progress "10" "$TOTAL"

		
		######################################
		#Questo passaggio potrebbe essere rimosso per via della creazione automatica fatta mediante apt-get update effettuata nel precendete passaggio.
		#echo "COPY FILE : nevis_repositories_Packages" >> $INSTALLER_LOG
		#cp "${APP_REPOSITORY_PATH}/var/lib/apt/lists/${APP_REPOSITORY_PACK}" "/var/lib/apt/lists/${APP_REPOSITORY_PACK}"
		update_progress "15" "$TOTAL"
		update_progress "20" "$TOTAL"
		update_progress "25" "$TOTAL"
		update_progress "30" "$TOTAL"
		update_progress "35" "$TOTAL"

		######################################
		#DEBIAN_FRONTEND=noninteractive apt-get remove -yq -o  python-dev
		declare -a packages=('gcc=4:4.9.2-2' 'vsftpd' 'cryptsetup' 'ffmpeg' 'python-psutil' 'python-setuptools' 'apache2' 'libapache2-mod-jk' 'libapache2-mod-wsgi' 'python-dev' 'ntpdate' 'snmp' 'snmp-mibs-downloader' 'snmpd' 'mergerfs' 'sudo');
		echo "THIRD PARTY PACKAGE: ${packages[@]}" >> $INSTALLER_LOG
		
		for i in "${packages[@]}"; do
			if [ $(dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
				echo "THIRD PARTY PACKAGE: $i INSTALLATION IN PROGRESS" >> $INSTALLER_LOG

				DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --allow-unauthenticated $i >> $INSTALLER_LOG
				
				#if [ "$i" == "gcc" ]; then
				#	echo "THIRD PARTY PACKAGE: $i and python LOCKED"
				#fi

			else
				echo "THIRD PARTY PACKAGE: $i HAS BEEN INSTALLED" >> $INSTALLER_LOG
				#echo "REMOVE: $i" >> $INSTALLER_LOG
				#DEBIAN_FRONTEND=noninteractive apt-get remove -qq -y --allow-unauthenticated $i >> $INSTALLER_LOG
				#echo "END: $i" >> $INSTALLER_LOG
				#echo "INSTALL: $i" >> $INSTALLER_LOG
				#DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --allow-unauthenticated $i >> $INSTALLER_LOG
				#echo "END: $i" >> $INSTALLER_LOG
			fi
		
		done

		echo "THIRD PARTY PACKAGE: $i and python LOCKED"
		apt-mark hold gcc
		apt-mark hold python
		
		update_progress "40" "$TOTAL"

		######################################
		if pip --version >/dev/null 2>&1; then
			echo "PIP: HAS BEEN INSTALLED" >> $INSTALLER_LOG
		else
			echo "PIP: INSTALLATION IN PROGRESS" >> $INSTALLER_LOG
			easy_install "${APP_CONFIG_PATH}/pip/pip-9.0.1.tar.gz"
		fi
		update_progress "45" "$TOTAL"
		update_progress "46" "$TOTAL"
		update_progress "47" "$TOTAL"
		update_progress "48" "$TOTAL"
		update_progress "49" "$TOTAL"

		######################################
		declare -a pippackages=('pytz-2017.3-py2.py3-none-any.whl' 'docopt-0.6.2.tar.gz' 'ptyprocess-0.5.2-py2.py3-none-any.whl' 'zope.interface-4.4.3-cp27-cp27mu-manylinux1_x86_64.whl' 'logging-0.4.9.6-cp27-none-any.whl' 'DateTime-4.2-py2.py3-none-any.whl' 'httpserver-1.1.0-py2.py3-none-any.whl' 'configparser-3.5.0.tar.gz' 'xmltodict-0.11.0-py2.py3-none-any.whl' 'dicttoxml-1.7.4.tar.gz' 'xmljson-0.1.9-py2.py3-none-any.whl' 'lxml-3.7.3-cp27-cp27mu-manylinux1_x86_64.whl' 'pexpect-4.2.1-py2.py3-none-any.whl' 'requests-2.13.0-py2.py3-none-any.whl' 'numpy-1.8.2-cp27-cp27mu-manylinux1_x86_64.whl' 'ntplib-0.3.3.tar.gz' 'netaddr-0.7.19-py2.py3-none-any.whl' 'itsdangerous-0.24.tar.gz' 'MarkupSafe-1.0.tar.gz' 'click-6.7-py2.py3-none-any.whl' 'Werkzeug-0.14.1-py2.py3-none-any.whl'  'Jinja2-2.10-py2.py3-none-any.whl' 'limits-1.2.1-py2-none-any.whl' 'Flask-0.12.2-py2.py3-none-any.whl' 'FlaskLimiter-1.0.1.tar.gz' 'SQLAlchemy-1.2.5.tar.gz' 'FlaskSQLAlchemy-2.1.tar.gz' 'PyJWT-1.6.1.tar.gz' 'FlaskJWTExtended-3.7.2.tar.gz' 'pycparser-2.18.tar.gz' 'six-1.11.0-py2.py3-none-any.whl' 'cffi-1.11.5-cp27-cp27mu-manylinux1_x86_64.whl' 'bcrypt-3.1.4-cp27-cp27mu-manylinux1_x86_64.whl' 'scandir-1.7.tar.gz'
		);
		for i in "${pippackages[@]}"; do
			IFS='-' read -a pippackagesname <<< "${i}"
			if [ $(pip list 2>/dev/null | grep -c "${pippackagesname[0]}"|awk '{print$1}') -eq 0 ]; then
				echo "PIP PACKAGE: $i INSTALLATION IN PROGRESS" >> $INSTALLER_LOG

				pip install "${APP_CONFIG_PATH}/pip/$i" >> $INSTALLER_LOG
				#DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --allow-unauthenticated $i >> $INSTALLER_LOG
			else
				echo "PIP PACKAGE: $i HAS BEEN INSTALLED" >> $INSTALLER_LOG
			fi
		done
		update_progress "50" "$TOTAL"
		update_progress "51" "$TOTAL"
		update_progress "52" "$TOTAL"
		update_progress "53" "$TOTAL"
		
		######################################
		echo "SET TIMEZONE UTC" >> $INSTALLER_LOG
		timedatectl set-timezone UTC
		update_progress "54" "$TOTAL"
		
	#if [[ $response == [sS] ]]; then

		######################################
		echo "JAVA INSTALL" >> $INSTALLER_LOG

		JAVAEXIST=$(which java)
		if [ ! -x "${JAVAEXIST}" ]; then
			echo "JAVA INSTALL: Java NOT EXIST." >> $INSTALLER_LOG
			mkdir -p "/opt/jre1.8.0_131"
			tar xzf "${APP_CONFIG_PATH}/java/jre-8u131-linux-x64.tar.gz" -C "/opt/jre1.8.0_131"
			update-alternatives --install /usr/bin/java java /opt/jre1.8.0_131/bin/java 1
			update-alternatives --set java /opt/jre1.8.0_131/bin/java
		else
			echo "JAVA INSTALL: Java Exists." >> $INSTALLER_LOG
		fi
		update_progress "55" "$TOTAL"
		
		######################################
		echo "TOMCAT INSTALL" >> $INSTALLER_LOG

		user_exist "$TOMCAT_USER"
		if [ $? -eq 0 ]; then
			echo "TOMCAT: <<$TOMCAT_USER>> user Exists." >> $INSTALLER_LOG
		else
			useradd -r $TOMCAT_USER --shell "/bin/false"
		    echo "TOMCAT: <<$TOMCAT_USER>> user does NOT EXIST. User Created." >> $INSTALLER_LOG
		fi
		update_progress "56" "$TOTAL"
				
		service_exist "tomcat"
		if [ $? != 0 ]
		 then
			echo "TOMCAT: Tomcat NOT EXIST. Tomcat added." >> $INSTALLER_LOG
			tar xzf "${APP_CONFIG_PATH}/tomcat/apache-tomcat-8.5.15.tar.gz" -C "/opt"
			ln -s "/opt/apache-tomcat-8.5.15" "/opt/tomcat-latest"
			
			echo "TOMCAT NEVIS CONFIG" >> $INSTALLER_LOG
			cp "${APP_CONFIG_PATH}/tomcat/tomcat.service" "/etc/systemd/system/tomcat.service"
			cp "${APP_CONFIG_PATH}/tomcat/context.xml" "/opt/tomcat-latest/webapps/manager/META-INF/context.xml"
			cp "${APP_CONFIG_PATH}/tomcat/startup.sh" "/opt/tomcat-latest/bin/startup.sh"
			cp "${APP_CONFIG_PATH}/tomcat/server.xml" "/opt/tomcat-latest/conf/server.xml"
			chown -hR tomcat:tomcat "/opt/tomcat-latest" "/opt/apache-tomcat-8.5.15"
			systemctl daemon-reload
			systemctl enable tomcat
			systemctl restart tomcat
		 else
			echo "TOMCAT: Tomcat has been added" >> $INSTALLER_LOG
		fi;
		update_progress "57" "$TOTAL"

		######################################
 		echo "APACHE2 NEVIS CONFIG" >> $INSTALLER_LOG
		cp "${APP_CONFIG_PATH}/apache2/ports.conf" "/etc/apache2/ports.conf"
		cp "${APP_CONFIG_PATH}/apache2/envvars" "/etc/apache2/envvars"
		cp "${APP_CONFIG_PATH}/apache2/000-default.conf" "/etc/apache2/sites-available/000-default.conf"
		cp "${APP_CONFIG_PATH}/apache2/workers.properties" "/etc/libapache2-mod-jk/workers.properties"
		apt-mark hold apache2 libapache2-mod-jk libapache2-mod-wsgi
		a2enmod headers
		service apache2 restart
		update_progress "58" "$TOTAL"
		
		######################################
		echo "SERVICES NEVIS" >> $INSTALLER_LOG
		service_exist "startstop"
		if [ $? != 0 ]
		 then
			echo "SERVICES NEVIS startstop: startstop NOT EXIST. startstop added." >> $INSTALLER_LOG
			cp "${APP_CONFIG_PATH}/services/startstop.service" "/etc/systemd/system/startstop.service"
			chmod +x "/etc/systemd/system/startstop.service"
			systemctl daemon-reload
			systemctl enable startstop.service
			#systemctl start startstop.service
		 else
			echo "SERVICES NEVIS: startstop has been added" >> $INSTALLER_LOG
		fi;
		update_progress "59" "$TOTAL"

		cp "${APP_CONFIG_PATH}/services/nevis.service" "/etc/systemd/system/nevis.service"
		chmod +x "/etc/systemd/system/nevis.service"
		systemctl daemon-reload
		systemctl enable nevis.service
		#systemctl start nevis.service
		echo "SERVICES NEVIS: nevis has been added" >> $INSTALLER_LOG
		update_progress "60" "$TOTAL"


		######################################
		echo "SNMP CONFIG" >> $INSTALLER_LOG
		iptables -A INPUT -p tcp -m tcp --dport 161 -j ACCEPT
		iptables -A INPUT -p udp -m udp --dport 161 -j ACCEPT
		iptables-save

		cp "${APP_CONFIG_PATH}/snmp/snmpd.conf" "/etc/snmp/snmpd.conf"

		systemctl enable snmpd
		systemctl restart snmpd
		systemctl status snmpd
		echo "SNMP CONFIG: SNMP NOT EXIST. SNMP added." >> $INSTALLER_LOG

		update_progress "61" "$TOTAL"

		######################################
		echo "CRONTAB NEVIS CONFIG" >> $INSTALLER_LOG
		addtocrontab "*/10 * * * *" "/nevis_app/nevis_latest/bin/slotCleaner"
		#service cron start
		update_progress "62" "$TOTAL"

		######################################
		echo "OTHER DEBIAN CONFIG" >> $INSTALLER_LOG
		echo "fs.inotify.max_user_instances = 1024" >> "/etc/sysctl.conf"
		echo 1024 > "/proc/sys/fs/inotify/max_user_instances"
		cp "${APP_CONFIG_PATH}/debian/limits.conf" "/etc/security/limits.conf"
		#swappiness add
		cp "${APP_CONFIG_PATH}/debian/sysctl.conf" "/etc/sysctl.conf"
		update_progress "63" "$TOTAL"

		######################################
		#echo "SUDO PACKAGE INSTALL" >> $INSTALLER_LOG
		#if [ $(dpkg-query -W -f='${Status}' "sudo" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
		#	echo "PACKAGE: sudo INSTALLATION IN PROGRESS" >> $INSTALLER_LOG
		#	dpkg -i "${APP_REPOSITORY_PATH}/sudo/sudo_1.8.10p3-1+deb8u5_amd64.deb"
		#else
		#	echo "PACKAGE: sudo HAS BEEN INSTALLED" >> $INSTALLER_LOG
		#fi
		
		
		######################################
		echo "NEVIS USER SUDO CONFIG" >> $INSTALLER_LOG
		user_exist "$NEVIS_USER"
		if [ $? -eq 0 ]; then
			echo "USER CONFIG: <<$NEVIS_USER>> user Exists." >> $INSTALLER_LOG
			usermod -aG sudo $NEVIS_USER
			echo $NEVIS_USER:$NEVIS_PASS | chpasswd
			echo "USER CONFIG: <<$NEVIS_USER>> usermod sudo." >> $INSTALLER_LOG
		else
			useradd -r $NEVIS_USER --shell "/bin/false"
			usermod -aG sudo $NEVIS_USER
			echo $NEVIS_USER:$NEVIS_PASS | chpasswd
		    echo "USER CONFIG: <<$NEVIS_USER>> user does NOT EXIST. User Created." >> $INSTALLER_LOG
		fi
		update_progress "64" "$TOTAL"
		
		######################################
		echo "POLFER USER CONFIG" >> $INSTALLER_LOG
		user_exist "$POLFER_USER"
		if [ $? -eq 0 ]; then
			echo $POLFER_USER:$NEVIS_PASS | chpasswd
			echo "USER CONFIG: <<$POLFER_USER>> user Exists." >> $INSTALLER_LOG
		else
			useradd -r $POLFER_USER --shell "/bin/false"
			echo $POLFER_USER:$NEVIS_PASS | chpasswd
		    echo "USER CONFIG: <<$POLFER_USER>> user does NOT EXIST. User Created." >> $INSTALLER_LOG
		fi
		update_progress "65" "$TOTAL"

		#####################################
		echo "CHANGE PASSWORD" >> $INSTALLER_LOG
		echo -e "$RTPD\n$RTPD" | passwd root >> $INSTALLER_LOG
		
		#echo "smonto"
		#umount "/nevis"
		#echo "rimuovo"
		#cryptsetup remove "/dev/mapper/videocrypt"
		######################################
		#V. 1.1.0
		####
		#
		#echo "LUKS SETUP: CRYPTSETUP partition format" >> $INSTALLER_LOG
		#cryptsetup_exist "videocrypt"
		#if [ $? = 0 ]; then
		#	echo "LUKS SETUP: CRYPTSETUP has been added" >> $INSTALLER_LOG
		#else
		#	deviceIsMounted "sda3"
		#	if [[ $? -eq 0 ]]; then
		#		echo "LUKS SETUP: CRYPTSETUP added" >> $INSTALLER_LOG
		#		echo $LUKSPASSWORD|cryptsetup -v luksFormat $LUKSROOTDEVICE >> $INSTALLER_LOG
		#		echo $LUKSPASSWORD|cryptsetup luksOpen $LUKSROOTDEVICE videocrypt >> $INSTALLER_LOG
		#		echo "LUKS SETUP: Creation file system to disk partioned" >> $INSTALLER_LOG
		#		mkfs.ext4  $LUKSMAPPER
		#		echo "LUKS SETUP: Mount partition" >> $INSTALLER_LOG
		#		mkdir -p $LUKSMOUNTPATH
		#		mount $LUKSMAPPER $LUKSMOUNTPATH
		#		mount -a
		#		chmod +x "${APP_CONFIG_PATH}/luks/luksRootPass"
		#		cd ${APP_CONFIG_PATH}/luks
		#		./luksRootPass ${LUKSPASSWORD}
		#		
		#	else
		#		echo "LUKS SETUP: Partition sda3 NOT Created! MUST BE CREATED and restart installation."
		#	fi
		#
		#fi		
		update_progress "66" "$TOTAL"

		######################################
		echo "RAMDISK SETUP" >> $INSTALLER_LOG		
		textinfile_exist "tmpfs" "/etc/fstab"
		if [ $? -eq 0 ]; then
			echo "RAMDISK SETUP: FSTAB has been added"
		else
			echo "RAMDISK SETUP: FSTAB added"
			mkdir -p $RAMDISKPATH
			mount -o size=$RAMDISKSIZE -t tmpfs none $RAMDISKPATH
			echo "tmpfs    $RAMDISKPATH tmpfs   nodev,nosuid,noexec,nodiratime,size=$RAMDISKSIZE   0 0" >> "/etc/fstab"
			mount -a
		fi
		update_progress "67" "$TOTAL"


		######################################
		echo "Start Luks / MergerFS Install and Config" >> $INSTALLER_LOG
		mkdir -p "$LUKSMOUNTPATH" && chmod 755 "$LUKSMOUNTPATH"
		chmod +x "${APP_CONFIG_PATH}/luks/luksCreation" && chmod +x "${APP_CONFIG_PATH}/luks/luksRootPassMulti"
		cd "${APP_CONFIG_PATH}/luks/"
		./luksCreation $LUKSUSERSLIST $LUKSPASSWORD
		
		update_progress "68" "$TOTAL"
		update_progress "70" "$TOTAL"
		
		######################################
		echo "START INSTALLATION NEVIS CORE" >> $INSTALLER_LOG
		chmod +x "${APP_BASE_PATH_INSTALLER}/nevisInstallDEB"
		cd ${APP_BASE_PATH_INSTALLER}
		./nevisInstallDEB
		
		update_progress "90" "$TOTAL"
		update_progress "100" "$TOTAL"
		echo "NeViS Surveillance INSTALLATO correttamente."
		echo "==== END INSTALL ====" >> $INSTALLER_LOG
		cleanup
	#else
		#echo "Installazione interrotta dall utente.";
		#cleanup
	#fi
}

main