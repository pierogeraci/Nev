#!/usr/bin/python

import thread
import sys
import datetime
import os
import time
import module.utility
import module.config
import module.globalvars
from flask import Flask, jsonify, abort, make_response, request
import xml.etree.ElementTree as ET
import pickle
import logging.handlers


# VARIABLES #########################################################

webAppName = 'uptimetServer'
app = Flask(webAppName)  # global app declaration
inDebug = False

# response codes
rc_bad_request = 400
rc_ok = 200
rc_internal_server_error = 500

# LOGGER START ######################################################

fileConfigIni = module.globalvars.NEVIS_CONFIG_INI # '/nevisApp/conf/config.ini'

formatter_us = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
handler_up = logging.handlers.TimedRotatingFileHandler(module.globalvars.LOG_FOLDER + "/log_uptime_server.log", when="midnight", backupCount=30)

handler_up.setFormatter(formatter_us)
logger_us = logging.getLogger()
logger_us.addHandler(handler_up)
logger_us.setLevel(logging.INFO)
logger_us.info("Log Rec List started...")

# FLASK METHODS #####################################################

@app.route('/keepAlive', methods=['GET'])
def keepAlive():

    response = {'Esito': 'OK', 'Descrizione': 'Keep Alive Response'}
    responseCode = rc_ok  # default ok

    try:

        return jsonify(response), responseCode

    except Exception as ex:

        # handle unexpected script errors
        response = {'Esito': 'KO', 'Descrizione': 'Exception Uptime Server metodo KeepAlive: {} - line {}'.format(ex, sys.exc_traceback.tb_lineno)}
        print('*** Exception Uptime Server keepAlive: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))

        return jsonify(response)      # 500 = internal server error


@app.route('/lastPowerOffAndStartUp', methods=['GET'])    # {"@id" : "001", "Status" : "Running"}
def lastPowerOffAndStartUp():

    try:

        response = None
        responseCode = rc_ok  # default ok

        lastStartUp, lastPowerOff = writeUptimeServer.calcLastPowerOffAndStartUp()

        response = {'Last Start Up': lastStartUp, 'Last Power Off': lastPowerOff}

        return jsonify(response)

    except Exception as ex:

        # handle unexpected script errors
        response = {'status': 'KO',
                    'error': 'Exception Uptime Server metodo lastPowerOffAndStartUp: {} - line {}'.format(ex, sys.exc_traceback.tb_lineno)}

        print('*** Exception Uptime Server metodo lastPowerOffAndStartUp: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))

        return jsonify(response), rc_internal_server_error  # 500 = internal server error


@app.route('/completeTimeline', methods=['GET'])
def completeList():

    try:

        response = None
        responseCode = rc_ok  # default ok

        # extract first column, readable
        listToReturn = [row[0] for row in writeUptimeServer.buffer]

        # return
        return jsonify(listToReturn)

    except Exception as ex:

        response = {'status': 'KO',
                    'error': 'Errore Uptime Server metodo completeTimeline: {} - line {}'.format(ex, sys.exc_traceback.tb_lineno)}

        print('*** Exception Uptime Server completeTimeline: {} - {}'.format(ex, sys.exc_traceback.tb_lineno))

        return jsonify(response), rc_internal_server_error  # 500 = internal server error


# SUPPORT CLASS #####################################################


class write_uptimeServer():
    """docstring for server_log."""

    def __init__(self):

        self.last_sent = datetime.datetime.now()
        self.outputFile = '/nevis_app/nevis_latest/conf/generated/uptimeServer.pickle'
        self.configFile = module.globalvars.NEVIS_CONFIG_XML
        self.outputSemaphoreBlock = False
        self.bufferLock = False
        self.maxMinutes = 12000
        self.cleanerType = ''
        self.buffer = []
        self.jsonDataInternal = {}

        self.loadFromXML()

        self.loadOldFile()      # to avoid errors when apache restarts

        # buffer fill loop
        #self.keepAliveBuffer()


    def loadFromXML(self):

        try:

            # open ws conf
            tree = ET.parse(self.configFile)
            root = tree.getroot()

            for child in root:

                if child.get('key') == 'path.log.uptimeServer':
                    self.outputFile = child.text
                    logger_us.info('*** Output File: {} - {}'.format(self.outputFile, child.text))

                if child.get('key') == 'video.maxMinutes':
                    self.maxMinutes = child.text
                    logger_us.info('*** Max Minutes: {} - {}'.format(self.maxMinutes, child.text))

                if child.get('key') == 'video.slotCleaner.type':
                    self.cleanerType = child.text
                    logger_us.info('*** Cleaner Type: {} - {}'.format(self.cleanerType, child.text))

        except Exception as ex:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            logger_us.error('*** ERROR Uptime Server loadFromXML: {} - line {}'.format(ex, exc_tb.tb_lineno))


    def loadOldFile(self):

        try:

            if os.path.isfile(self.outputFile):    # if it exists, load it

                while True:

                    if self.bufferLock is False:

                        self.bufferLock = True
                        self.buffer = pickle.load(open(self.outputFile, "rb"))
                        logger_us.info('*** Uptime Server loadOldFile: Loaded Old File')
                        self.bufferLock = False

                        break

                    else:

                        time.sleep(0.5)

        except Exception as ex:

            exc_type, exc_obj, exc_tb = sys.exc_info()
            logger_us.error('*** ERROR loadOldFile, deleting: {} - line {}'.format(ex, exc_tb.tb_lineno))
            # delete file
            os.remove(self.outputFile)


    def run(self):

        # run threat to avoid being stuck in a loop
        keepAlive_t = thread.start_new_thread(self.keepAliveBuffer, ())


    def keepAliveBuffer(self):

        while True:

            timeReadable = time.strftime('%Y-%m-%d_%H-%M', time.localtime())    # no seconds
            timeObject = datetime.datetime.now()
            timeObject = timeObject.replace(second=0, microsecond=0)    # set to beginning of the minute

            if len(self.buffer) != 0:

                # read last record to avoid duplicates
                if self.buffer[len(self.buffer) - 1][0] != timeReadable:

                    while True:

                        if self.bufferLock is False:

                            self.bufferLock = True
                            self.buffer.append([timeReadable,timeObject])
                            self.bufferLock = False

                            break

                        else:

                            time.sleep(0.5)

            else:

                while True:

                    if self.bufferLock is False:

                        self.bufferLock = True
                        self.buffer.append([timeReadable, timeObject])
                        self.bufferLock = False

                        break

                    else:

                        time.sleep(0.5)

            self.cleanBufferSelector()

            #print(self.buffer)

            time.sleep(55)

    def cleanBufferSelector(self):

        if self.cleanerType == 'solar':

            self.cleanBufferSolar()

        else:

            self.cleanBufferNonSolar()


    def cleanBufferSolar(self):

        while len(self.buffer) > 0:

            # extract datetime
            tempDate = self.buffer[0][1]

            # add max minutes
            tempDate += datetime.timedelta(minutes = int(self.maxMinutes))

            # compare to now
            if tempDate < datetime.datetime.now():  # too old, erease

                while True:

                    if self.bufferLock is False:

                        self.bufferLock = True
                        self.buffer.pop(0)
                        self.bufferLock = False

                    break

                else:

                    time.sleep(0.5)

            else:

                # break when you meet a record inside the visibility frame
                break


    def cleanBufferNonSolar(self):

        if len(self.buffer) > self.maxMinutes:

            difference = len(self.buffer) - self.maxMinutes

            while True:

                if self.bufferLock is False:

                    self.bufferLock = True
                    tempBuffer = self.buffer[difference:len(self.buffer)]
                    self.bufferLock = False

                    break

                else:

                    time.sleep(0.5)


    def calcLastPowerOffAndStartUp(self):

        try:

            lastPowerOff = 'Out of Time Frame'
            lastStartUp = 'Out of Time Frame'

            if len(self.buffer) != 0:

                # copy buffer
                while True:

                    if self.bufferLock is False:

                        self.bufferLock = True
                        tempBuffer = self.buffer
                        self.bufferLock = False

                        break

                    else:

                        time.sleep(0.5)

                # reverse buffer
                tempBuffer = tempBuffer[::-1]

                if len(tempBuffer) > 1:

                    for i in range(len(tempBuffer) - 1):

                        #print('date compatisons: ', tempBuffer[i][1], tempBuffer[i + 1][1])

                        # if the time difference between a minute and the next is more than 60 seconds, there was a poweroff
                        if (tempBuffer[i][1] - tempBuffer[i + 1][1]).seconds > 60:

                            # extract readable date
                            lastStartUp = tempBuffer[i][0]
                            lastPowerOff = tempBuffer[i + 1][0]

                            break

            logger_us.info('Request calcLastPowerOffAndStartUp: {} - {}'.format(lastStartUp, lastPowerOff))

            return lastStartUp, lastPowerOff

        except Exception as ex:

            exc_type, exc_obj, exc_tb = sys.exc_info()
            logger_us.error('*** ERROR calcLastPowerOffAndStartUp: {} - line {}'.format(ex, exc_tb.tb_lineno))


    def writeToFile(self):

        try:

            while True:

                if self.bufferLock is False:

                    self.bufferLock = True
                    # save as serialized object
                    pickle.dump(self.buffer, open(self.outputFile, "wb+"))
                    self.bufferLock = False

                    break

                else:

                    time.sleep(0.5)


        except Exception as ex:

            exc_type, exc_obj, exc_tb = sys.exc_info()
            logger_us.error('*** ERROR checkRecListStatus Check Status Camera: {} - line {}'.format(ex, exc_tb.tb_lineno))


    def readStatus(self, jsondata):         # {"@id" = "001"}

        returnValue = None

        for element in self.jsonDataInternal['Cams']['Cam']:

            if element['@id'] == jsondata['@id']:

                returnValue = element['Status']

        return returnValue


# threaded function to commit every X seconds
def committer():

    last_sent = datetime.datetime.now()
    while True:
        time.sleep(1)
        time_delta = (datetime.datetime.now() - last_sent).seconds
        if time_delta > 55:
            try:
                writeUptimeServer.writeToFile()
                last_sent = datetime.datetime.now()
            except Exception as ex:
                exc_type, exc_obj, exc_tb = sys.exc_info()
                logger_us.error('*** Uptime Server Committer: {} - line {}'.format(ex, exc_tb.tb_lineno))
                last_sent = datetime.datetime.now()


writeUptimeServer = write_uptimeServer()  # global log server declaration
commit_t = thread.start_new_thread(committer, ())  # commit thread
writeUptimeServer.run()


if __name__=='__main__':

    app.run()
