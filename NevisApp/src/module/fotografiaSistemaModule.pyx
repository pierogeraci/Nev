import sys
sys.path.append('..')
import nevis_is as nis
import time
import globalvars
import LocalData as LocalData
import ntpCheckModule
import json
import xml.etree.ElementTree as ET
import requests
import os
import psutil

def calcFotografia():

	response = {'cpuPerc': '',
				'ramPerc': '',
				'spazioDiscoPerc': '',
				'spazioDiscoSlot': '',
				'numeroRegistrazioniAttive': '',
				'numeroRegistrazioniErrore': '',
				'numeroStreamUnicast': '',
				'numeroStreamMulticast': '',
				'ultimoPowerOff': '',
				'ultimoStartUp': '',
				'systemTime': '',
				'ntpTime': '',
				'ntpCode': '',
				'nevisVersion': '',
				'configVersion': '',
				"licenseFlag": 0,
				"confDisksFlag": 0,
				"disksFlag": 0,
				"archiveFlag": 0,
				"nevisEngineFlag": 0
				}

	try:

		mountPoint, urlServerStatus, urlRecordings, urlUptimeServer, urlStreamUnicast, urlStreamMulticast, nevisDir, camsConfJson, alarmsJson, ntpServer = calcFotografiaXML()

		### calc CPU %, RAM %, Spazio Disco %, Spazio disco Slot
		#urlServerStatus = 'http://10.28.0.56:8080/api/v1/settings/serverStatus'
		dummyPayload = {'1': '1'}
		#resp = requests.post(urlServerStatus, data=dummyPayload)
		#resp = json.loads(resp.text)

		response['cpuPerc'] = psutil.cpu_percent()

		ram = psutil.phymem_usage()
		response['ramPerc'] = ram.percent

		disk = psutil.disk_usage(mountPoint)
		response['spazioDiscoPerc'] = disk.percent

		#response['spazioDiscoSlot'] = disk.total - disk.free inizialmente viene un calcolo sballato che tiene conto dello spazio perso per LUKS
		response['spazioDiscoSlot'] = disk.used

		### registrazioni attive/in errore
		numOfRecordings = 0
		numOfErrors = 0
		for k, v in LocalData.cams.iteritems():
			if v['statusRecording'] == 'Running':
				numOfRecordings += 1
			else:
				numOfErrors += 1
		response['numeroRegistrazioniAttive'] = numOfRecordings
		response['numeroRegistrazioniErrore'] = numOfErrors

		### last power off and start up
		#urlUptimeServer = 'http://10.28.0.56:8080/api/v1/uptimeServer/lastPowerOffAndStartUp'
		resp3 = requests.get(urlUptimeServer)
		resp3 = json.loads(resp3.text)

		response['ultimoPowerOff'] = resp3['Last Power Off']
		response['ultimoStartUp'] = resp3['Last Start Up']

		# Numero Stream Unicast/Multicast
		streamingLiveActive = len(nis.get_process_id("hls"))
		response['numeroStreamUnicast'] = int(streamingLiveActive)

		numberOfMulticastStreams = len(nis.get_process_id("udp"))
		response['numeroStreamMulticast'] = int(numberOfMulticastStreams)

		### time
		response['systemTime'] = time.strftime('%Y-%m-%d_%H-%M-%S', time.localtime())

		# NTP
		ntpTime = ntpCheckModule.ntpCheckFunc(ntpServer)
		response['ntpTime'] = ntpTime

		# NTP Code
		if response['ntpTime'] == response['systemTime']:
			response['ntpCode'] = 100		# ok
		elif response['ntpTime'] == 'Error':
			response['ntpCode'] = 102  		# Error
		else:
			response['ntpCode'] = 101		# Orario non sincronizzato con Server NTP

		# Nevis Version
		tempPath = os.path.realpath(nevisDir)		# resolve link
		version = tempPath.split('_')[-1]
		response['nevisVersion'] = version

		# Config Version
		configV = nis.get_cams_conf()
		response['configVersion'] = configV['configVersion']

		# open alarms file
		with open(alarmsJson, "rb") as f:  # notice the "rb" mode

			alarmsJsonDict = json.load(f)

			response['licenseFlag'] = alarmsJsonDict['license']
			response['confDisksFlag'] = alarmsJsonDict['confDisks']
			response['disksFlag'] = alarmsJsonDict['disks']
			response['archiveFlag'] = alarmsJsonDict['archive']
			response['nevisEngineFlag'] = alarmsJsonDict['nevisEngine']

		return response

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'Esito': 'KO', 'Descrizione': 'Exception calcFotografia: {} - line {}'.format(ex, exc_tb.tb_lineno)}
		print('*** Exception calcFotografia: {} - {}'.format(ex, exc_tb.tb_lineno))

		return response  # 500 = internal server error


def getFolderSize(p):
	from functools import partial
	prepend = partial(os.path.join, p)
	return sum([(os.path.getsize(f) if os.path.isfile(f) else getFolderSize(f)) for f in map(prepend, os.listdir(p))])


def calcFotografiaXML():

	try:

		mountPoint = ''
		urlServerStatus = ''
		urlRecordings = ''
		urlUptimeServer = ''
		urlStreamUnicast = ''
		urlStreamMulticast = ''
		nevisDir = ''
		camsConfJson = ''
		ntpServer = 'it.pool.ntp.org'
		# MS - fix ntp 20190429
		camsConfPath = ''

		# open ws conf
		tree = ET.parse(globalvars.NEVIS_CONFIG_XML)
		root = tree.getroot()

		for child in root:

			if child.get('key') == 'path.registrazioni':
				mountPoint = child.text
				#print('*** mountPoint: {} - {}'.format(mountPoint, child.text))

			if child.get('key') == 'ws.endpoint.local.serverStatus':
				urlServerStatus = child.text
				#print('*** urlServerStatus: {} - {}'.format(urlServerStatus, child.text))

			if child.get('key') == 'ws.endpoint.local.recordings':
				urlRecordings = child.text
				#print('*** urlRecordings: {} - {}'.format(urlRecordings, child.text))

			if child.get('key') == 'ws.endpoint.local.uptimeServer':
				urlUptimeServer = child.text
				#print('*** urlUptimeServer: {} - {}'.format(urlUptimeServer, child.text))

			if child.get('key') == 'ws.endpoint.local.streamUnicast':
				urlStreamUnicast = child.text
				#print('*** urlStreamUnicast: {} - {}'.format(urlStreamUnicast, child.text))

			if child.get('key') == 'ws.endpoint.local.streamMulticast':
				urlStreamMulticast = child.text
				#print('*** urlStreamMulticast: {} - {}'.format(urlStreamMulticast, child.text))

			if child.get('key') == 'path.root.nevis':
				nevisDir = child.text
				#print('*** nevisDir: {} - {}'.format(nevisDir, child.text))

			if child.get('key') == 'path.camsConfJson':
				camsConfJson = child.text
				#print('*** camsConfJson: {} - {}'.format(camsConfJson, child.text))

			if child.get('key') == 'path.alarmsJson':
				alarmsJson = child.text
				#print('*** camsConfJson: {} - {}'.format(alarmsJson, child.text))

            # MS - fix ntp 20190429
			if child.get('key') == 'path.camsConfJson':
				camsConfPath = child.text
				#print('*** camsConfPath: {}'.format(camsConfPath))

				with open(camsConfPath, 'r') as camsConfFile:
					tempDict = json.load(camsConfFile)
					if 'NTPServer' in tempDict:
						ntpServer = tempDict['NTPServer']

		return mountPoint, urlServerStatus, urlRecordings, urlUptimeServer, urlStreamUnicast, urlStreamMulticast, nevisDir, camsConfJson, alarmsJson, ntpServer


	except Exception as ex:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print('*** ERROR Uptime Server loadFromXML: {} - line {}'.format(ex, exc_tb.tb_lineno))


if __name__ == '__main__':

	calcFotografia()