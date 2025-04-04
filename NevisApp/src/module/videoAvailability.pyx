# From version 3 it has filters
# Version 6 new short mode
# v15 deprecata modalita' full
import os
import sys
import time
import pyLogger
import globalvars
import utcTranslator
import xml.etree.ElementTree as ET
import datetime
import re


logger = pyLogger.pyLoggerClass()

class videoAvailabilityClass(object): # Concat with no Blanks

	def __init__(self, params={}):

		try:
			self.timezone = params['timezone']
			#self.startDate = params['startDate'] #+ '-00'
			self.startDate = utcTranslator.translateToUTC( params['startDate'] + '-00', '%Y-%m-%d_%H-%M-%S', self.timezone)
			#self.endDate = params['endDate'] #+ '-59'
			self.endDate = 	utcTranslator.translateToUTC( params['endDate'] + '-59', '%Y-%m-%d_%H-%M-%S', self.timezone)
			self.videoSourceId = params['videoSourceId']
			

			self.baseRecordingsPath = '/nevis/'
			self.slotFolder = None

			self.getVarsFromXML()

			self.path = None

			self.error=''
			self.outputDict = {'list': [],
							   'startDate': params['startDate'] + '-00',
							   'endDate': params['endDate'] + '-59'}

		except Exception as e:

			self.error = str(e)
			exc_type, exc_obj, exc_tb = sys.exc_info()
			if isDebug_videoAvailability(): print('*** ERROR checkRecListStatus Check Status Camera: {} - line {}'.format(e, exc_tb.tb_lineno))
			logger.sendLogMsg('VIDEO_AVAILABILITY', 'ERROR', '*** Exception Init: {} - {}'.format(e, exc_tb.tb_lineno))


	def getVarsFromXML(self):

		if isDebug_videoAvailability(): print('*** Start getVarsFromXML')

		confFile = globalvars.NEVIS_CONFIG_XML          # '/nevisApp/conf/config.xml'

		# open empty video file path
		tree = ET.parse(confFile)
		root = tree.getroot()

		for child in root:
			if child.get('key') == 'path.registrazioni':
				self.baseRecordingsPath = child.text
				if isDebug_videoAvailability(): print('*** Base Recordings Path: {} - {}'.format(self.baseRecordingsPath, child.text))


	# short version, just start and end of every recording
	def composeDictSinglePathShort(self, startIndex, stopIndex):

		element = None

		try:

			tempDict = None
			tempList = []

			# loop vars
			firstIterationStartStopSearch = True

			logger.sendLogMsg('VIDEO_AVAILABILITY', 'DEBUG', '*** Start Video Availability Recompose Blind - Short')

			totalSize = 0

			dateTemp = ''
			difference = 0
			lastDateTemp = None
			tempStart = None
			tempStop = None

			# search for valid video files between
			for root, dirs, files in os.walk(self.path):

				files.sort()

				for element in files:

					if '_' in element and '-' in element and '.ts' in element:  # avoid temp files

						#print(element)

						# extract date from filename 004_A_03_HD_2017-07-13_12-59-00_bcad28cd7979.ts -> 2017-07-13_12-59
						dateTemp = element.split('_')[4] + '_' + element.split('_')[5] # day + '_' + time
						dateTempDuration = element.split('_')[7]
						dateTempDuration = int(dateTempDuration.split('.ts')[0])

						# recompose
						if dateTemp >= self.startDate and dateTemp <= self.endDate:  # valid date in file

							# logger.sendLogMsg('VIDEO_AVAILABILITY', 'DEBUG', '*** Date comparison (prev-actual): {} - {}'.format(lastDateTemp, dateTemp))

							# set first start date
							if firstIterationStartStopSearch:

								tempStart = dateTemp
								firstIterationStartStopSearch = False

								lastDateTemp = dateTemp
								lastDateTempDuration = dateTempDuration

							# look for a date with an empty minute before i
							elif not firstIterationStartStopSearch:

								resultDifferenceBool = self.checkSecondsDifference(lastDateTemp, lastDateTempDuration, dateTemp)

								if resultDifferenceBool:      # True = gap found

									tempStop = self.calcLastDateTemp(lastDateTemp, lastDateTempDuration) #lastDateTemp

									if tempStop is None:
										tempStop = tempStop[:-3] + '-59'

									#tempList.append([tempStart, tempStop])
									tempList.append([utcTranslator.translateFromUTC(tempStart, '%Y-%m-%d_%H-%M-%S', self.timezone), utcTranslator.translateFromUTC(tempStop, '%Y-%m-%d_%H-%M-%S', self.timezone)])

									# reset tempStart for next iteration
									tempStart = dateTemp


								lastDateTemp = dateTemp
								lastDateTempDuration = dateTempDuration

				if lastDateTemp is not None:

					tempStop = self.calcLastDateTemp(lastDateTemp, lastDateTempDuration)  # lastDateTemp

					if tempStop is None:
						tempStop = tempStop[:-3] + '-59'

					# last element
					tempList.append([utcTranslator.translateFromUTC(tempStart, '%Y-%m-%d_%H-%M-%S', self.timezone), utcTranslator.translateFromUTC(tempStop, '%Y-%m-%d_%H-%M-%S', self.timezone)])

				# break loop
				break

			# check if tempList
			if len(tempList) != 0:

				tempDict = {'videoSourceId': self.slotFolder.split('_')[2], 'quality': self.slotFolder.split('_')[-1], 'slotId': self.slotFolder.split('_')[0], 'Availability': tempList}

			return tempDict

		except Exception as e:

			self.error = str(e)
			exc_type, exc_obj, exc_tb = sys.exc_info()
			print('*** ERROR composeDictSinglePathShort: {} - line {} - file {}'.format(e, exc_tb.tb_lineno, element))
			logger.sendLogMsg('VIDEO_AVAILABILITY', 'ERROR', '*** Exception composeDictSinglePathShort: {} - {}  file {}'.format(e, exc_tb.tb_lineno, element))


	def calcLastDateTemp(self, lastDateTemp, lastDateTempDuration):

		dateStrOutput = None

		dateObj = datetime.datetime.strptime(lastDateTemp, "%Y-%m-%d_%H-%M-%S")
		dateObjOutput = dateObj + datetime.timedelta(0, int(lastDateTempDuration))
		dateStrOutput = dateObjOutput.strftime("%Y-%m-%d_%H-%M-%S")

		return dateStrOutput


	def checkSecondsDifference(self, firstDate, firstDateDuration, lastDate):

		resultDifferenceBool = False		# False = consecutive files, True = time gap between files

		if isDebug_videoAvailability(): print('*** First and Last date: {} - {}'.format(firstDate, lastDate))

		differenceInSeconds = 0

		firstDateObj = datetime.datetime.strptime(firstDate, "%Y-%m-%d_%H-%M-%S")
		lastDateObj = datetime.datetime.strptime(lastDate, "%Y-%m-%d_%H-%M-%S")

		differenceInSeconds = (lastDateObj - firstDateObj).total_seconds()

		firstDateDuration += 2		# account for decimal place precision on both first date and second date

		if int(firstDateDuration) >= int(differenceInSeconds):

			resultDifferenceBool = False

		else:

			resultDifferenceBool = True

		return resultDifferenceBool


	def calcMinDifference2(self, firstDate, lastDate):

		if isDebug_videoAvailability(): print('*** First and Last date: {} - {}'.format(firstDate, lastDate))

		difference = 0

		firstDateObj = datetime.datetime.strptime(firstDate, "%Y-%m-%d_%H-%M")
		lastDateObj = datetime.datetime.strptime(lastDate, "%Y-%m-%d_%H-%M")

		if firstDateObj == lastDateObj:

			difference = 0

		elif firstDateObj < lastDateObj:

			timeDifference = lastDateObj - firstDateObj

			# calculate the days of difference and the seconds of differene
			# Difference in seconds does not excede a single day
			# Difference in days is zero if less than a day

			secondsDifference = timeDifference.seconds
			daysDifference = timeDifference.days

			# difference in minues
			difference = daysDifference*24*60 + secondsDifference/60

		return difference


	def calcMinDifference(self, firstDate, lastDate):

		if isDebug_videoAvailability(): print('*** First and Last date: {} - {}'.format(firstDate, lastDate))

		difference = 0

		if firstDate == lastDate:

			difference = 0

		elif firstDate < lastDate:

			firstMinute = int(firstDate.split('_')[1].split('-')[1])
			lastMinute = int(lastDate.split('_')[1].split('-')[1])

			if isDebug_videoAvailability(): print('*** First and Last minute: {} - {}'.format(firstMinute, lastMinute))

			if firstMinute < lastMinute:

				difference = (lastMinute - firstMinute)

			else:

				difference = ((60 - firstMinute) + lastMinute)

		return difference


	def findIndexes(self):

		logger.sendLogMsg('VIDEO_AVAILABILITY', 'DEBUG', '*** Start findIndexes')

		startIndex = -1
		stopIndex = -1

		for root, dirs, files in os.walk(self.path):

			files.sort()

			for element in files:
				if self.startDate in element:
					startIndex = files.index(element)
					logger.sendLogMsg('VIDEO_AVAILABILITY', 'DEBUG', '*** Start Index Trovato: {}'.format(startIndex))
					print('*** Start Index Found: {}'.format(startIndex))

				if self.endDate in element:
					stopIndex = files.index(element)
					logger.sendLogMsg('VIDEO_AVAILABILITY', 'DEBUG', '*** Stop Index Trovato: {}'.format(stopIndex))
					print('*** Stop Index Found: {}'.format(stopIndex))
					break

		return startIndex, stopIndex


	def calcDatesForFolder(self, fullPath):

		startDate = None
		endDate = None

		# find start date and end date for folder
		for root, dirs, files in os.walk(fullPath):

			if len(files) == 0 or files is None:  # delete forlder if empty

				startDate = 'Directory Vuota'
				endDate = 'Directory Vuota'

			elif len(files) == 1:

				startDate = self.extractDate(files[0])
				endDate = startDate

			elif len(files) >= 2:

				files.sort()

				startDate = self.extractDate(files[0])
				endDate = self.extractDate(files[-1])

		return startDate, endDate


	def composeDictAllFolders(self):

		for root, dirs, files in os.walk(self.baseRecordingsPath):

			# make unique set list
			for singleDir in dirs:

				if len(singleDir) > 5 and '_' in str(singleDir) and self.videoSourceId in singleDir:  # trying to avoid non-slot folders

					# if <self.videoSourceId is ''> then <self.videoSourceId in singleDir> is always true

					self.slotFolder = singleDir
					self.path = self.baseRecordingsPath + singleDir

					startIndex, stopIndex = self.findIndexes()
					tempDict = None

					tempDict = self.composeDictSinglePathShort(startIndex, stopIndex)

					if tempDict is not None:

						self.outputDict['list'].append(tempDict)

			break

		print('*** Output Dict: {}'.format(self.outputDict))


	def checkDates(self):

		result = True
		errorMsg = ''

		regCheck = '\d{4}-\d{2}-\d{2}\_\d{2}-\d{2}-\d{2}' #verify dates
		patternToTest = re.compile(regCheck)

		if self.startDate == '' or self.endDate == '':
			result = False
			errorMsg = 'Start Date o End Date vuota'
			return result, errorMsg

		if not patternToTest.match(self.startDate) or not patternToTest.match(self.endDate)	or len(self.startDate) != 19 or len(self.endDate) != 19:
			result = False
			errorMsg = 'Date non valide'
			return result, errorMsg

		if self.startDate >= self.endDate:
			result = False
			errorMsg = 'Start Date maggiore di End Date'

		return result, errorMsg


	def execute(self):

		try:

			checkDatesResult, errorMsg = self.checkDates()

			if checkDatesResult:

				self.composeDictAllFolders()

			else:

				self.error = errorMsg
				logger.sendLogMsg('VIDEO_AVAILABILITY', 'ERROR', errorMsg)

		except Exception as e:

			self.error = str(e)
			exc_type, exc_obj, exc_tb = sys.exc_info()
			if isDebug_videoAvailability(): print('*** ERROR checkRecListStatus Check Status Camera: {} - line {}'.format(e, exc_tb.tb_lineno))
			logger.sendLogMsg('VIDEO_AVAILABILITY', 'ERROR', '*** Exception Init: {} - {}'.format(e, exc_tb.tb_lineno))



def isDebug_videoAvailability():

	valueToReturn = False
	return valueToReturn


#test
if __name__ == "__main__":

	start_time = time.time()

	params = {'startDate' : '2018-03-01_15-30',
			  'endDate': '2018-03-02_18-30',
			  'videoSourceId': ''
			  }

	obj = videoAvailabilityClass(params)

	obj.execute()

	print('Execution time {} seconds'.format(time.time() - start_time))

	logger.sendLogMsg('VIDEO_AVAILABILITY', 'DEBUG', 'Execution time {} seconds'.format(time.time() - start_time))
	if isDebug_videoAvailability(): print('*** Execution time {} seconds'.format(time.time() - start_time))