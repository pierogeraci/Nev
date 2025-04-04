#!/usr/bin/python
import subprocess
import sys
from flask import Flask, jsonify, abort, make_response, request
import pyLogger
# VARIABLES #########################################################
webAppName = 'nevisServiceUpdate'
app = Flask(webAppName)

nevisServiceLogger = pyLogger.pyLoggerClass()

portNumber = 8890

# response codes
rc_bad_request = 400
rc_ok = 200
rc_internal_server_error = 500

# commands
commandStopRecordings = 'systemctl stop nevis.service'
commandStartRecordings = 'systemctl start nevis.service'

commandStopApache = 'systemctl stop apache2'
commandStartApache = 'systemctl start apache2'

commandStopTomcat = 'systemctl stop tomcat'
commandStartTomcat = 'systemctl start tomcat'

# GET SECTION #######################################################
@app.route('/stopRecordings', methods=['GET'])
def stopRecordings():

    response = None
    responseCode = rc_ok  # default ok

    try:

        exitCode = commandsHandler(commandStopRecordings)

        if exitCode == 0:

            response = {'status': 'OK',
                        'msg': 'Metodo stopRecordings: Comando eseguito correttamente'}

        else:

            response = {'status': 'KO',
                        'msg': 'Metodo stopRecordings: Comando non eseguito correttamente. Exit Code: {}'.format(exitCode)}

        nevisServiceLogger.sendLogMsg('START_STOP', 'DEBUG', '*** Operation stopRecordings: {} - {}'.format(response['status'], response['msg']))

        return jsonify(response), responseCode

    except Exception as ex:

        # handle unexpected script errors
        if isDebug_videoAvailability(): print('Unhandled error stopRecordings: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))
        response = {'status': 'KO', 'msg': 'Exception stopRecordings: {} - line {}'.format(ex, sys.exc_traceback.tb_lineno)}
        nevisServiceLogger.sendLogMsg('START_STOP', 'ERROR', '*** Exception stopRecordings: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))

        return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/startRecordings', methods=['GET'])
def startRecordings():

    response = None
    responseCode = rc_ok  # default ok

    try:

        exitCode = commandsHandler(commandStartRecordings)

        if exitCode == 0:

            response = {'status': 'OK',
                        'msg': 'Metodo startRecordings: Comando eseguito correttamente'}

        else:

            response = {'status': 'KO',
                        'msg': 'Metodo startRecordings: Comando non eseguito correttamente. Exit Code: {}'.format(
                            exitCode)}

        nevisServiceLogger.sendLogMsg('START_STOP', 'DEBUG', '*** Operation startRecordings: {} - {}'.format(response['status'], response['msg']))

        return jsonify(response), responseCode

    except Exception as ex:

        # handle unexpected script errors
        if isDebug_videoAvailability(): print('Unhandled error startRecordings: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))
        response = {'status': 'KO', 'msg': 'Exception startRecordings: {} - line {}'.format(ex, sys.exc_traceback.tb_lineno)}
        nevisServiceLogger.sendLogMsg('START_STOP', 'ERROR', '*** Exception startRecordings: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))

        return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/fullStop', methods=['GET'])
def fullStop():

    response = None
    responseCode = rc_ok  # default ok

    try:

        nevisServiceLogger.sendLogMsg('START_STOP', 'DEBUG', '*** Operation fullStop')

        exitCode1 = commandsHandler(commandStopRecordings) # Nevis
        exitCode3 = commandsHandler(commandStopTomcat) # Tomcat
        exitCode2 = commandsHandler(commandStopApache) # Apache

        if exitCode1 == 0 and exitCode2 == 0 and exitCode3 == 0:

            response = {'status': 'OK',
                        'msg': 'Metodo fullStop: Comando eseguito correttamente'}

        else:

            response = {'status': 'KO',
                        'msg': 'Metodo fullStop: Comando non eseguito correttamente. Exit Codes: stop recordings {} - stop Apache {} - stop Tomcat {}'.format(
                            exitCode1, exitCode2, exitCode3)}

        return jsonify(response), responseCode

    except Exception as ex:

        # handle unexpected script errors
        if isDebug_videoAvailability(): print('Unhandled error fullStop: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))
        response = {'status': 'KO', 'msg': 'Exception fullStop: {} - line {}'.format(ex, sys.exc_traceback.tb_lineno)}
        nevisServiceLogger.sendLogMsg('START_STOP', 'ERROR', '*** Exception fullStop: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))

        return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/startNevisUpdate', methods=['GET'])
def startNevisUpdate():
    response = None
    responseCode = rc_ok  # default ok
    try:

        exitCode1 = commandsHandler(commandStartRecordings) # Nevis
        exitCode2 = commandsHandler(commandStartApache) # Apache
        exitCode3 = commandsHandler(commandStartTomcat) # Tomcat

        if exitCode1 == 0 and exitCode2 == 0 and exitCode3 == 0:
            response = {'status': 'OK', 'msg': 'Il sistema ha avviato correttamente la verifica del file di aggiornamento.'}
        else:
            response = {'status': 'KO',
                        'msg': 'Il sistema di aggiornamento si è interrotto: Comando non eseguito correttamente. Exit Codes: stop recordings {} - stop Apache {} - stop Tomcat {}'.format(
                            exitCode1, exitCode2, exitCode3)}

        nevisServiceLogger.sendLogMsg('START_STOP', 'DEBUG', '*** Operation fullStart: {} - {}'.format(response['status'], response['msg']))

        return jsonify(response), responseCode

    except Exception as ex:

        # handle unexpected script errors
        if isDebug_videoAvailability(): print('Unhandled error fullStart: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))
        response = {'status': 'KO', 'msg': 'Exception fullStart: {} - line {}'.format(ex, sys.exc_traceback.tb_lineno)}
        nevisServiceLogger.sendLogMsg('START_STOP', 'ERROR', '*** Exception fullStop: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))

        return jsonify(response), rc_internal_server_error  # 500 = internal server error

def commandsHandler(command):

    exitCode = None

    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()
    exitCode = process.returncode

    return exitCode

def isDebug_videoAvailability():

    valueToReturn = True
    return valueToReturn

if __name__ == '__main__':
    # init run
    app.run(host='0.0.0.0', port=portNumber)        # host='0.0.0.0' listens to outside messages, not only localhost
