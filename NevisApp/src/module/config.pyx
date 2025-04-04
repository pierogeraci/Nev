#13/07/2017
#Config file reading module, reads the config.ini and creates the local shared
#variables
import os, sys, getopt
from ConfigParser import SafeConfigParser

def GetConfiguration(fileConfig):
	import module.globalvars
	try:
		parser = SafeConfigParser()
		parser.read(fileConfig)
		module.globalvars.LOG_MANAGER_HOST= parser.get('LOG_MANAGER', 'LOG_MANAGER_HOST')
		module.globalvars.LOG_MANAGER_PORT= parser.get('LOG_MANAGER', 'LOG_MANAGER_PORT')
		module.globalvars.LOG_FOLDER= parser.get('SETTINGS', 'LOG_FOLDER')
		module.globalvars.NEVIS_IS_PORT= parser.get('NEVIS_IS', 'NEVIS_IS_PORT')
		module.globalvars.NEVIS_IS_MULTICAST_EXPIRE= parser.get('NEVIS_IS', 'NEVIS_IS_MULTICAST_EXPIRE')
		module.globalvars.NEVIS_SERVICE_FOLDER= parser.get('SETTINGS', 'SERVICE_FOLDER')
		module.globalvars.NEVIS_CONFIG_FOLDER= parser.get('SETTINGS', 'CONFIG_FOLDER')
		module.globalvars.NEVIS_CAMS_CONF = parser.get('SETTINGS', 'CAMS_CONF')
		module.globalvars.NEVIS_DISCOVERY_NETWORK_LIST_CAMS_URL_PATH = parser.get('DISCOVERY_NETWORK', 'DISCOVERY_NETWORK_LIST_CAMS_URL_PATH')
		module.globalvars.NEVIS_LIST_CAMS_MANUAL_FILE = parser.get('LOAD_BALANCER', 'LIST_CAMS_MANUAL_FILE')
		module.globalvars.DEFAULT_TIME_ZONE = parser.get('SETTINGS', 'DEFAULT_TIME_ZONE')

	except getopt.GetoptError:
		print 'Error read Config File...',fileConfig
		sys.exit(2)