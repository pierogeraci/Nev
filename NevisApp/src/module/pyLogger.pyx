import xml.etree.ElementTree as ET
import time
import urllib2
import json
import traceback
import sys
import globalvars

class pyLoggerClass:

    pathConfWs = globalvars.NEVIS_CONFIG_XML        # '/nevisApp/conf/config.xml'
    logUrl = 'http://localhost:8080/api/system/addlog' # default


    def __init__(self):

        self.importFromXML()


    def importFromXML(self):

        # open ws conf
        tree = ET.parse(self.pathConfWs)
        root = tree.getroot()

        for child in root:
            if child.get('key') == 'ws.endpoint.local.logger':
                self.logUrl = child.text
                #print('*** log Url: {} - {}'.format(self.logUrl, child.text))


    def sendLogMsg(self, process, type, msgString):

        try:

            msg = None

            if type in ['DEBUG', 'ERROR']:

                # create data
                msg = {'process': process,
                    'msg_type': type,
                    'log': {'TIMESTAMP': str(time.time()).split('.')[0] + '000',  # str
                           'MSG': str(msgString)  # int
                           }
                   }

            else:

                print('*** ERROR Sending Log, type is: {}'.format(type))

            if msg is not None:

                self.sendLog(msg)

        except Exception as e:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            print('*** ERROR sendLogMsg: {} - line {}'.format(e, exc_tb.tb_lineno))

    def sendLog(self, msgData):

        # temp static url
        #self.logUrl = 'http://10.28.0.56:8889/api/v1/addlog'
        try:
            req = urllib2.Request(self.logUrl)
            req.add_header('Content-Type', 'application/json')
            #print(json.dumps(msgData))
            response = urllib2.urlopen(req, json.dumps(msgData))
            #print(response)
        except Exception as e:
            traceback.print_exc(file=sys.stdout)
