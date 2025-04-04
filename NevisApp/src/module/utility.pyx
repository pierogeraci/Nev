#11/29/2016
#utility module used for monitoring, configuration and keep-alive purposes
import time
import module.globalvars
import module.config
import threading
import json
import os, sys, getopt

class RefreshConfiguration(threading.Thread):
    def __init__(self,threadID):
        threading.Thread.__init__(self)
        self.threadID = threadID

    def run(self):
        while True:
            #print "File di configurazione: -" + module.globalvars.CONFIGFILE + "-"
            if len(module.globalvars.CONFIGFILE)>0:
                #print "Carico il file di configurazione..."
                module.config.GetConfiguration(module.globalvars.CONFIGFILE)
            time.sleep(module.globalvars.SLEEP)


def main(argv):
    cConfigFile = ''
    try:
        if len(sys.argv)<2:
            raise getopt.GetoptError("")

        opts, args = getopt.getopt(argv,"hc:",["ConfigFile="])

        if len(opts)<1:
            raise getopt.GetoptError("")

    except getopt.GetoptError:
        print 'main.py -c <configFile>'
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print 'main.py -c <configFile>'
            sys.exit()
        elif opt in ("-c", "--ConfigFile"):
            cConfigFile = arg
            print 'init...'
            print cConfigFile
            module.config.GetConfiguration(cConfigFile)