#!/bin/bash
exec 2> /nevis_app/nevis_latest/log/startupnevis.log  # send stderr from rc.local to a log file
exec 1>&2                      # send stdout to the same log file
set -x                         # tell sh to display commands before execution

#NEVIS STARTUP
#nginx
#service nginx start
#Il servizio è stato modificato per avviarsi in automatico

function_to_fork() {

echo $$

sleep 20

#/nevis_app/nevis_latest/bin/log_manager.sh -start

/nevis_app/nevis_latest/bin/nevis_engine.sh -start

/nevis_app/nevis_latest/bin/nevis_monitor.sh -start

#/nevis_app/nevis_latest/bin/nevis_is.sh -start

sleep 10
}

function_to_fork &
