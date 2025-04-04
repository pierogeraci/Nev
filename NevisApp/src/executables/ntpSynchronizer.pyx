#!/usr/bin/python
from datetime import datetime
from datetime import timedelta
import json
import module.globalvars
import module.pyLogger
import ntplib
import pytz
from subprocess import check_output
from subprocess import CalledProcessError
import xml.etree.ElementTree as ET


#init pyLogger
logger = module.pyLogger.pyLoggerClass()
TDELTA_THRESHOLD = timedelta(minutes=-1)
TDELTA_ZERO = timedelta()

def main():
	
	#print 'Procedura di Sincronizzazione NTP - INIZIO'
	logger.sendLogMsg('NTP_SYNCHRONIZER', 'DEBUG', '***** Procedura di Sincronizzazione NTP - INIZIO *****')
	
	ntpServerAddress = getVarsFromXML()
	ntpClient = ntplib.NTPClient()
	try:
		# call ntp server
		responseNTP = ntpClient.request(ntpServerAddress, version=3)
		ntpDate = datetime.fromtimestamp(responseNTP.tx_time, pytz.utc)
		ntpDate = ntpDate.replace(microsecond=0)
		#print 'Data da NTP Server: {}'.format(str(ntpDate))
		logger.sendLogMsg('NTP_SYNCHRONIZER', 'DEBUG', 'Data da NTP Server: {}'.format(str(ntpDate)))
		
		localDate = datetime.now(pytz.utc)
		localDate = localDate.replace(microsecond=0)
		#print 'Data locale: {}'.format(str(localDate))
		logger.sendLogMsg('NTP_SYNCHRONIZER', 'DEBUG', 'Data locale: {}'.format(str(localDate)))
		
		
		if ntpDate == localDate:
			#print 'Sincronizzazione NTP non necessaria'
			logger.sendLogMsg('NTP_SYNCHRONIZER', 'DEBUG', 'Sincronizzazione non necessaria')
		else:
			tdelta = ntpDate - localDate
			
			if tdelta < TDELTA_ZERO:
				#print 'Data locale - Data NTP = {}'.format(str( -tdelta )) 
				logger.sendLogMsg('NTP_SYNCHRONIZER', 'DEBUG', 'Data locale - Data NTP = {}'.format(str( -tdelta ))) 
			else :
				#print 'Data NTP - data locale = {}'.format(str( -tdelta )) 
				logger.sendLogMsg('NTP_SYNCHRONIZER', 'DEBUG', 'Data NTP - Data locale = {}'.format(str( tdelta ))) 
						
			
			if tdelta > TDELTA_THRESHOLD:
				try:
					check_output(['ntpdate', ntpServerAddress])
					#print 'Effettuata Sincronizzazione NTP'
					logger.sendLogMsg('NTP_SYNCHRONIZER', 'DEBUG', 'Effettuata Sincronizzazione NTP')
				except CalledProcessError as cpe:
					#print 'Comando ntpdate in errore -  {}'.format(cpe)
					logger.sendLogMsg('NTP_SYNCHRONIZER', 'ERROR', 'Errore durante la procedura di sincronizzazione NTP -  {}'.format(cpe))
			else:
				#print 'Data locale successiva alla data NTP di una delta maggiore di 1 minuto. Non posso procedere alla sincronizzazione'
				logger.sendLogMsg('NTP_SYNCHRONIZER', 'DEBUG', 'Data locale successiva alla data NTP di una delta maggiore di 1 minuto. Non posso procedere alla sincronizzazione')

			
	except Exception as ex:
		#print 'Errore durante la procedura di sincronizzazione NTP -  {}'.format(ex)
		logger.sendLogMsg('NTP_SYNCHRONIZER', 'ERROR', 'Errore durante la procedura di sincronizzazione NTP -  {}'.format(ex))
	
	
	#print 'Procedura di Sincronizzazione NTP - FINE.'
	logger.sendLogMsg('NTP_SYNCHRONIZER', 'DEBUG', '***** Procedura di Sincronizzazione NTP - FINE *****')

	
def getVarsFromXML():

	ntpServer = 'it.pool.ntp.org'
	confFile = module.globalvars.NEVIS_CONFIG_XML

	tree1 = ET.parse(confFile)
	root1 = tree1.getroot()

	for child in root1:
		# MS - fix ntp 20190507
		if child.get('key') == 'path.camsConfJson':
			camsConfPath = child.text
			#print('*** camsConfPath: {}'.format(camsConfPath))

			with open(camsConfPath, 'r') as camsConfFile:
				tempDict = json.load(camsConfFile)
				if 'NTPServer' in tempDict:
					ntpServer = tempDict['NTPServer']

	return ntpServer

	
if __name__=="__main__":
	main()