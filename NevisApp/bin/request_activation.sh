#!/bin/bash
# script starting nevis activation request generator



BASEDIR=/nevis_app/nevis_latest
export NEVIS_HOME=$BASEDIR
. "$BASEDIR/bin/setenv.sh"

${JAVA} -jar ${EXEDIR}/nevislicenseactivation.jar