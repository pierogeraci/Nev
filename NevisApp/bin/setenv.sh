#!/bin/bash
# common
typeset -r BASEDIR=/nevis_app/nevis_latest
typeset -r CFGDIR=${BASEDIR}/conf
typeset -r LOGDIR=${BASEDIR}/log
typeset -r EXEDIR=${BASEDIR}/bin

CFGFILE=${CFGDIR}/config.ini

typeset -r PYTHON=/usr/bin/python
typeset -r JAVA=/usr/bin/java

typeset -r LOG_SERVER_EXE=${EXEDIR}/log_server.pyc
typeset -r LOG_SERVER_LOG=${LOGDIR}/log_server.log
typeset -r NEVIS_IS_EXE=${EXEDIR}/nevis_is.pyc
typeset -r NEVIS_IS_LOG=${LOGDIR}/nevis_is.log
typeset -r NEVIS_MONITOR_EXE=${EXEDIR}/nevisthreadmonitor.jar
typeset -r NEVIS_ENGINE_EXE=${EXEDIR}/nevisengine.jar


