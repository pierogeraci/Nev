#!/bin/bash
# starting script for nevis monitor
# version 1.0, date 20170428

#BASEDIR=`cd "$PWD/.." >/dev/null; pwd`
BASEDIR=/nevis_app/nevis_latest
export NEVIS_HOME=$BASEDIR
. "$BASEDIR/bin/setenv.sh"
typeset -A nevis_monitor_pids

function do_check_procs {
	unset nevis_monitor_pids
  
	idxArr=0
	for pid in $(ps -adef | grep -i ${NEVIS_MONITOR_EXE} | grep -v grep | awk '{ print $2 }'); do
		nevis_monitor_pids[$idxArr]=$pid
		((idxArr=idxArr+1))
	done
}

function do_stop {
  do_check_procs
  if [[ ${#nevis_monitor_pids[@]} -gt 0 || ${#nevis_monitor_pids[@]} -gt 0 ]]; then
    printf "Killing Nevis Monitor: "
    for pid in ${nevis_monitor_pids[@]}; do
      echo $pid
      kill -15 $pid > /dev/null 2>&1
    done
  fi
}

function do_start {
  do_status
  if [[ ${#nevis_monitor_pids[@]} -gt 0 || ${#nevis_monitor_pids[@]} -gt 0 ]]; then
    echo "Nevis Monitor is already running. Please use ${me} -restart to restart."
  else
    # run Nevis Integration Services
	echo "Starting Nevis MONITOR .."
	echo "${JAVA} -jar ${NEVIS_MONITOR_EXE}" | at now 2>/dev/null
  fi
}

function do_status {
  do_check_procs
  if [[ ${#nevis_monitor_pids[@]} -gt 0 || ${#nevis_monitor_pids[@]} -gt 0 ]]; then
    printf "%s " "Running Nevis Monitor processes:"
    echo ${nevis_monitor_pids[@]}
  else
	echo "There are no running processes."
  fi
}

function usage {
   echo "Usage: ${me} -start | -restart | -stop | -status"
}

# execute
case $1 in
    -status) do_status
            ;;
     -start) echo "Start Nevis Monitor if not running."
             do_start
            ;;
      -stop) echo "Stop Nevis Monitor if running."
             do_stop
            ;;
   -restart) do_stop
             echo "Restart Nevis Monitor."
             do_start
            ;;
           *) usage
              exit 1
            ;;
esac