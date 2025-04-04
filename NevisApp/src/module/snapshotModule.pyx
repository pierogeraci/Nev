import requests
import shutil
import time
import pyLogger
import globalvars
import xml.etree.ElementTree as ET
import json
import sys
import urllib
import os


# define logger
snapshotLogger = pyLogger.pyLoggerClass()


def getVarsFromXML():

	# call rec list service
	confFile = globalvars.NEVIS_CONFIG_XML  # '/nevisApp/conf/config.xml'
	outputPath = None
	recListUrl = None

	# open empty video file path
	tree = ET.parse(confFile)
	root = tree.getroot()

	for child in root:

		if child.get('key') == 'path.snapshot':
			outputPath = child.text

		if child.get('key') == 'ws.endpoint.local.recordings':
			recListUrl = child.text

	return recListUrl, outputPath


def getIpFromVideoSourceId(recListUrl, videoSourceId):

	cameraInfo = {}

	# call rec list, complete list
	resp = requests.get(recListUrl)
	resp = json.loads(resp.text)

	# select correct camera
	for element in resp['Cams']['Cam']:

		if element['VideoSourceId'] == videoSourceId:

			cameraInfo['ip'] = element['Ip']
			cameraInfo['user'] = element['Username']
			cameraInfo['password'] = urllib.quote(element['Password'])      # urllib quote takes care of special chars
			cameraInfo['vendor'] = element['Vendor']
			cameraInfo['url'] = element['Url']

	return cameraInfo


def getImagePathFromUrl(videoSourceId, completeUrl, outputPath):

	path = outputPath + 'snapshot_' + videoSourceId + '_' + str(time.time()).split('.')[0] + '.jpg'
	responseText = None

	r = requests.get(completeUrl, stream=True)

	if r.status_code == 200:

		with open(path, 'wb') as f:

			shutil.copyfileobj(r.raw, f)

	else:	# error

		path = None
		responseText = r.text

	return path, responseText


def calcSnapshotUrl(cameraInfo):

	completeUrl = None

	if cameraInfo['vendor'].lower() == 'hikvision':

		completeUrl = 'http://' + cameraInfo['user'] + ':' + cameraInfo['password'] + '@' + cameraInfo['ip'] + \
						cameraInfo['url'].split(cameraInfo['ip'])[1] + '/picture'

	elif cameraInfo['vendor'].lower() == 'axis':

		completeUrl = 'http://' + cameraInfo['ip'] + '/axis-cgi/jpg/image.cgi'

	elif cameraInfo['vendor'].lower() == 'vivotek':

		completeUrl = 'http://' + cameraInfo['user'] + ':' + cameraInfo['password'] + '@' + cameraInfo['ip'] + '/cgi-bin/viewer/video.jpg'

	return completeUrl


def getSnapshot(videoSourceId):

	result = {'status': '', 'msg': ''}

	try:

		recListUrl, outputPath = getVarsFromXML()

		if not os.path.exists(outputPath):
			os.makedirs(outputPath)

		cameraInfo = getIpFromVideoSourceId(recListUrl, videoSourceId)

		if cameraInfo:  # if not empty

			completeUrl = calcSnapshotUrl(cameraInfo)

			if completeUrl is not None:

				imagePath, responseText = getImagePathFromUrl(videoSourceId, completeUrl, outputPath)

				if imagePath is not None:

					imagePathFTP = imagePath.split('/nevis/public')[1]

					result = {'status': 'ok', 'pathFTP': imagePathFTP, 'videoSourceId': videoSourceId}

					snapshotLogger.sendLogMsg('SNAPSHOT', 'INFO', '*** Snapshot successful: {} - {}'.format(videoSourceId, imagePath))

				else:

					result = {'status': 'KO', 'msg': str(responseText)}
					snapshotLogger.sendLogMsg('SNAPSHOT', 'ERROR',
											  '*** KO getSnapshot: {}'.format(str(responseText)))

		else:

			result = {'status': 'KO', 'msg': 'Camera non trovata'}

		return result

	except Exception as e:

		exc_type, exc_obj, exc_tb = sys.exc_info()
		result = {'status': 'ko', 'msg': '*** Exception getSnapshot: {} - {}'.format(e, exc_tb.tb_lineno)}
		snapshotLogger.sendLogMsg('SNAPSHOT', 'ERROR', '*** Exception getSnapshot: {} - {}'.format(e, exc_tb.tb_lineno))
		return result


# used for testing
if __name__ == "__main__":

	start_time = time.time()

	videoSourceId = 'cam-test-h265'

	imagePath = getSnapshot(videoSourceId)

	print(imagePath)

	print("*** Execution time {} seconds".format(time.time() - start_time))