# Version with preview and no DB
# Version 26, no more empty videos
# Version 27, removed time and size check for external calls
# V 28 fixed wrong slot path bug

import os
import sys
import re
import time
import string
import random
import subprocess
import pyLogger
import globalvars
import xml.etree.ElementTree as ET
import hashlib
#from shutil import copyfile


logger = pyLogger.pyLoggerClass()

chars = string.ascii_letters + string.digits
def generateRandom(length):
	"""Return a random string of specified length (used for session id's)"""
	return ''.join([random.choice(chars) for i in range(length)])

class concatenate(object): # Concat with no Blanks

	def __init__(self, params={}):

		self.path="/nevis/" + params["path"] + "/"
		self.camId=params["path"]
		self.startDate=params["startDate"]
		self.endDate=params["endDate"]
		self.sessionId=params["sessionId"]
		self.requestId=params["idRequest"]
		self.quality=params["quality"]
		self.md5VideoFile = ''
		self.pathFTP = ''

		if params['encoder'] == 'native':
			self.previewMode = False
		else:
			self.previewMode = True

		if 'limits' not in params:
			self.limits = False
		elif params['limits'] == 'True':
			self.limits = True
		else:
			self.limits = False

		self.error=''
		regCheck = '\d{4}-\d{2}-\d{2}\_\d{2}-\d{2}' #verify dates
		patternToTest = re.compile(regCheck)
		self.outputFolder = '/nevis/public/history/'
		self.limitSize = 209715200 #200MB limit default
		self.minuteLimit = 0 # counts the number of minutes before the limit is reached
		self.totalSize = 0
		self.outputFile = ''

		self.previewVertResolution = '360'
		self.previewFrameRate = '5'

		self.getVarsFromXML()

		if self.path[-1:] != '/':
			self.path = self.path + '/'

		#check dates
		if patternToTest.match(self.startDate) and patternToTest.match(self.endDate):
			logger.sendLogMsg('CONCAT', 'DEBUG', '*** Date Valide')
			print('*** Valid Dates')
		else:
			logger.sendLogMsg('CONCAT', 'ERROR', '*** Error: Date non valide')
			print('*** Error: Dates not valid')
			self.error = "Date non valide"
			return None

		if self.startDate >= self.endDate:
			logger.sendLogMsg('CONCAT', 'ERROR', '*** Error: Start Date maggiore o uguale di End Date')
			print('*** Error: Start Date maggiore o uguale di End Date')
			self.error = "Start Date maggiore o uguale di End Date"
			return None

		'''
		if self.quality != self.camId.split('_')[-1]:
			logger.sendLogMsg('CONCAT', 'ERROR', '*** Error: Qualita selezionata non presente su questo NVR')
			self.error = 'Qualita selezionata non presente su questo NVR'
			return None
		'''

	def getVarsFromXML(self):

		print('*** Start getVarsFromXML')

		confFile = globalvars.NEVIS_CONFIG_XML
		#confVideoPath = '/root/nevis/conf/config_video.xml'

		outputFolder = None

		# open config file path
		tree = ET.parse(confFile)
		root = tree.getroot()

		for child in root:

			if child.get('key') == 'path.registrazioni.storico':
				self.outputFolder = child.text
				print('*** Output Folder: {} - {}'.format(self.outputFolder, child.text))

			if child.get('key') == 'video.concatenate.limit.bytes':
				self.limitSize = int(child.text)
				print('*** Limit Size: {} - {}'.format(self.limitSize, child.text))

			if child.get('key') == 'video.asyncHistory.preview.vertResolution':
				self.previewVertResolution = child.text
				print('*** previewVertResolution: {} - {}'.format(self.previewVertResolution, child.text))

			if child.get('key') == 'video.asyncHistory.preview.frameRate':
				self.previewFrameRate = child.text
				print('*** previewFrameRate: {} - {}'.format(self.previewFrameRate, child.text))


	def findIndexes(self):
		logger.sendLogMsg('CONCAT', 'DEBUG', '*** Start findIndexes')
		print('*** Start findIndexes')
		startIndex = -1
		stopIndex = -1

		for root, dirs, files in os.walk(self.path):
			files.sort()
			for element in files:
				if self.startDate in element:
					startIndex = files.index(element)
					logger.sendLogMsg('CONCAT', 'DEBUG', '*** Start Index Trovato: {}'.format(startIndex))
					print('*** Start Index Found: {}'.format(startIndex))

				if self.endDate in element:
					stopIndex = files.index(element)
					logger.sendLogMsg('CONCAT', 'DEBUG', '*** Stop Index Trovato: {}'.format(stopIndex))
					print('*** Stop Index Found: {}'.format(stopIndex))
		print('*** End findIndexes')
		return startIndex, stopIndex


	# recompose files, based on date/filename search
	def recomposeBlind(self, startDate, endDate):

		listFileName = str(self.requestId + '_' + self.sessionId + '_' + self.camId + "_" + self.startDate + '_' + self.endDate +  '.txt')
		logger.sendLogMsg('CONCAT', 'DEBUG', '*** Filename: {}'.format(listFileName))

		if not os.path.exists(self.outputFolder):
			os.makedirs(self.outputFolder)

		tempPath = self.outputFolder
		self.outputFile = tempPath + listFileName.split('.txt')[0] + '.mp4' #swap file extension

		print('*** Output File Name:{}'.format(self.outputFile))

		# file list open
		tempListObj = open(tempPath + listFileName, 'w')

		# loop vars
		#firstIteration = True

		logger.sendLogMsg('CONCAT', 'DEBUG', '*** Start Recompose Blind')
		print('*** Start Recompose Blind')

		#empty check, to avoid empty files
		#emptyCheck = True
		#stopProcess = False

		#previousMinute = -1000 #Check if minutes are consecutive. Start value is intentionally wrong
		totalSize = 0

		dateTemp = ''
		#difference = 0

		#search for valid video files between
		for root, dirs, files in os.walk(self.path):

			files.sort()

			for element in files:

				if '_' in element and '-' in element and '.ts' in element: #avoid temp files

					#print(element)
					#extract date from filename 004_A_03_HD_2017-07-13_12-59-00_bcad28cd7979.ts -> 2017-07-13_12-59
					dateTemp = element.split('_')[4] + '_' + element.split('_')[5].split('-')[0] + '-' + element.split('_')[5].split('-')[1] #day + '_' + time

					#recompose
					if dateTemp >= startDate and dateTemp <= endDate: #valid date in file

						if self.limits:
							# Check Total Size
							self.addToTotalSize(self.path + element)

							# self.limitSize = 50000000  # ~50MB test size
							if (self.totalSize >= self.limitSize):  # file too large, break

								# rename output file
								logger.sendLogMsg('CONCAT', 'ERROR', '*** File troppo grande, processo interrotto. Limite raggiunto in {} minuti di registrazione'.format(self.minuteLimit))
								self.error='*** File troppo grande, processo interrotto. Limite raggiunto in {} minuti di registrazione'.format(self.minuteLimit)
								self.outputFile = self.outputFile.split('.mp4')[0] + '_truncated.mp4'
								stopProcess = True
								break

						# file path + name
						fileNameAndPath = self.path + element
						tempListObj.write('file \'' + fileNameAndPath + '\'\n')

			tempListObj.close()

		#check if tempListObj is not empty, if it is, return error

		statinfo = os.stat(tempPath + listFileName)
		tempListObjSize = statinfo.st_size

		if tempListObjSize != 0:

			#exec command
			command = 'ffmpeg -y -f concat -safe 0 -i '+ tempPath + listFileName + ' -c copy ' + self.outputFile
			process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
			process.wait()

			print('*** Command - Filename: {} - {}'.format(command,tempPath + listFileName))

			if self.previewMode:
				# create new file with parameters

				previeFileName =  self.outputFile.split('.mp4')[0] + '_preview_mode.mp4'       # add _previe_mode

				# -1 preserves the aspect ratio
				command = 'ffmpeg -y -i ' + self.outputFile + ' -vf scale=-1:' + self.previewVertResolution + ' -r ' + self.previewFrameRate + ' ' + previeFileName
				process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
				process.wait()

				# delete old file
				os.remove(self.outputFile)

				# change output file
				self.outputFile = previeFileName

			# md5
			self.md5VideoFile = hashlib.md5(open(self.outputFile, 'rb').read()).hexdigest()

			# pathFTP
			self.pathFTP = self.outputFile.split('/nevis/public')[1]

			self.outputFile = self.outputFile.split('/history/')[1]
			print('*** outputFile - error: {} - {}'.format(self.outputFile,self.error))

			logger.sendLogMsg('CONCAT', 'DEBUG', '*** Concat Output File: {}'.format(self.outputFile))

		else:

			self.error = 'Registrazione vuota'
			logger.sendLogMsg('CONCAT', 'ERROR', '*** Concat Registrazione Vuota')

		print('*** End Recompose Blind')


	def getFileLength(self, filename):

		result = subprocess.Popen(["ffprobe", filename],stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		tempList = [x for x in result.stdout.readlines() if "Duration" in x][0]

		duration = tempList.split(',')[0]
		duration = duration.split('Duration')[1]
		duration = duration[1:]

		durationInSeconds = float(duration.split(':')[1]) * 60 + float(duration.split(':')[2])  # min * 60 + seconds.cent seconds

		return durationInSeconds


	def addToTotalSize(self, fullPath):

		statinfo = os.stat(fullPath)
		elementSize = statinfo.st_size
		self.totalSize = self.totalSize + elementSize
		self.minuteLimit += 1


	def calcMinDifference(self, firstDate, lastDate):

		print('*** First and Last date: {} - {}'.format(firstDate, lastDate))

		difference = 0

		if firstDate == lastDate:

			difference = 0

		elif firstDate < lastDate:

			firstMinute = int(firstDate.split('_')[1].split('-')[1])
			lastMinute = int(lastDate.split('_')[1].split('-')[1])

			print('*** First and Last minute: {} - {}'.format(firstMinute, lastMinute))

			if firstMinute < lastMinute:

				difference = (lastMinute - firstMinute)

			else:

				difference = ((60 - firstMinute) + lastMinute)

		return difference


	def hourLimitCheck(self):

		greenLightHourLimit = False

		# preparing vars for comparison
		startDateDate = self.startDate.split('_')[0]
		startDateTime = self.startDate.split('_')[1]
		endDateDate = self.endDate.split('_')[0]
		endDateTime = self.endDate.split('_')[1]

		startNumOfMinutes = int(startDateTime.split('-')[0])*60 + int(startDateTime.split('-')[1])     # hours*60 + minutes
		endNumOfMinutes = int(endDateTime.split('-')[0])*60 + int(endDateTime.split('-')[1])         # hours*60 + minutes

		print('*** startNumOfMinutes - endNumOfMinutes: {} - {}'.format(startNumOfMinutes,endNumOfMinutes))

		if (startDateDate == endDateDate) and ((endNumOfMinutes - startNumOfMinutes) <= 60):

			greenLightHourLimit = True

		else: # error, difference > 60 minutes

			greenLightHourLimit = False
			logger.sendLogMsg('CONCAT', 'ERROR', '*** Error: La differenza fra data di inizio e data fine deve essere minore di 60 minuti')
			self.error = '*** Error: La differenza fra data di inizio e data fine deve essere minore di 60 minuti'

		return greenLightHourLimit


	def execute(self):

		greenLightHourLimit = True

		if self.limits:

			greenLightHourLimit = self.hourLimitCheck()

		if greenLightHourLimit or not self.limits:

			self.recomposeBlind(self.startDate, self.endDate)  # put files togather


#test
if __name__ == "__main__":

	start_time = time.time()

	params = {'path': '121_M_S1-01-vest-testata-aero-o1-05_HD',
			'startDate' : '2018-02-20_12-05',
			'endDate': '2018-02-20_12-09',
			'sessionId': 'testid3',
			'idRequest': 'request123',
			'encoder': 'preview',
			'quality': 'HD',
			'limits': 'False'}

	obj = concatenate(params)
	obj.execute()

	print("*** Execution time {} seconds".format(time.time() - start_time))


'''

NEW HIKVISION

	params = {'path': '001_M_CAM1_HD',
			'startDate' : '2017-12-04_16-00',
			'endDate': '2017-12-04_16-30',
			'sessionId': 'testid3',
			'idRequest': 'request123',
			'encoder': 'native',
			'quality': 'HD',
			'limits': 'False'}

	params = {'path': '002_M_99_HD',
			'startDate' : '2017-09-04_12-15',
			'endDate': '2017-09-04_12-37',
			'sessionId': 'testid3',
			'idRequest': 'request123',
			'encoder': 'native',
			'quality': 'HD',
			'limits': 'True'}			

------

'''