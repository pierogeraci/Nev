#!/bin/sh
exec 2> /tmp/stopnevis.log     # send stderr from rc.local to a log file
exec 1>&2                      # send stdout to the same log file
set -x                         # tell sh to display commands before execution

touch /var/lock/subsys/local

#NEVIS STOP
#nginx
#Il servizio è stato modificato per avviarsi in automatico

#/root/nevis/bin/nevis_is.sh -stop

/nevis_app/nevis_latest/bin/nevis_monitor.sh -stop

/nevis_app/nevis_latest/bin/nevis_engine.sh -stop

#/nevis_app/nevis_latest/bin/log_manager.sh -stop

