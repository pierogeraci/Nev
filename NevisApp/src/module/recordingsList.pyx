'''
Author: Michele Sarchioto
Date: 11/07/2017
Notes: New dirs structure
v4 check if range is empty
'''

import os
import pyLogger
import globalvars
import xml.etree.ElementTree as ET
import time
import json
from operator import itemgetter, attrgetter
import shutil
import utcTranslator


#init pyLogger
logger = pyLogger.pyLoggerClass()

class recordingsList:

	outputJson = None
	error = ''

	def __init__(self, params):

		if 'startDate' in params and 'endDate' in params and 'quality' in params:

			self.timezone = params["timezone"]
		
			#self.inputStartDate = params["startDate"]
			self.inputStartDate = utcTranslator.translateToUTC( params["startDate"], '%Y-%m-%d_%H-%M', self.timezone)
			#self.inputEndDate = params["endDate"]
			self.inputEndDate = utcTranslator.translateToUTC( params["endDate"], '%Y-%m-%d_%H-%M', self.timezone)
			self.quality = params["quality"]
			

			self.recordingsList_start()

		else: # malformed json param

			self.error = 'Parametri di ingresso malformati'
			logger.sendLogMsg('RECORDING_LIST', 'ERROR', '*** Parametri di ingresso malformati')

	def getSlotVarsFromXML(self):

		confPath = globalvars.NEVIS_CONFIG_XML      # '/home/nevis/conf/config.xml'
		dirRootPath = '/nevis/' # default value

		tree1 = ET.parse(confPath)
		root1 = tree1.getroot()

		for child in root1:
			if child.get('key') == 'path.registrazioni':
				pathName = child.text
				logger.sendLogMsg('RECORDING_LIST', 'DEBUG', '*** path.registrazioni: {} - {}'.format(pathName, child.text))
				print('*** path.registrazioni: {} - {}'.format(pathName, child.text))

		return pathName


	def recordingsList_start(self):

		try:

			start_time = time.time()

			logger.sendLogMsg('RECORDING_LIST','DEBUG', '*** Start Recordings List')

			dirRootPath = self.getSlotVarsFromXML()

			#maxMinutes = 60 # for testing

			# check dir
			if dirRootPath[-1:] != '/': # check if last char is '/'
				dirRootPath = dirRootPath + '/'

			listDirs = []
			setDirs = []    # set = list of unique values
			arrayDirs = []

			for root, dirs, files in os.walk(dirRootPath):

				# make unique set list
				for element in dirs: # for every subdir extract left 5

					if '_' in str(element):

						listDirs.append('_'.join((element.split('_')[0],element.split('_')[1])))

				setDirs = set(listDirs)
				print('*** setDirs: {}'.format(setDirs))

				setDirs = list(setDirs)     # change type back to list to be indexable

				# separate files in groups, based on their folder
				if len(setDirs) != 0 and setDirs is not None:

					for index in range(len(setDirs)):

						arrayDirs.append([])    # append empty list

						for element in dirs:

							if '_' in str(element):
								elemPrefix = '_'.join((element.split('_')[0],element.split('_')[1]))
							else:
								elemPrefix = element

							if str(setDirs[index]) == str(elemPrefix):

								arrayDirs[index].append(element)

					print('*** arrayDirs: {}'.format(arrayDirs))

					# build the dictionary
					outputDict = {}

					for index in range(len(setDirs)):

						arrayDict = []
						dictIndex = setDirs[index].split('_')[0]
						outputDict.update({dictIndex: {}})

						for element in arrayDirs[index]:

							tempDict = ()

							emptyBool = self.calcEmptyRange(dirRootPath + element)

							if emptyBool is False:

								startDate, endDate = self.calcDatesForFolder(dirRootPath + element)

								if self.quality != '' and self.inputStartDate != '' and self.inputEndDate  != '':     # no filter

									if self.quality in element and self.inputStartDate <= endDate and self.inputEndDate >= startDate:

										#tempDict = ({'folderName' : element,
										#				 'startDate' : startDate,
										#				 'endDate': endDate
										#				 })
										#Traduzione date da UTC
										tempDict = ({'folderName': element,
												 'startDate': utcTranslator.translateFromUTC( startDate, '%Y-%m-%d_%H-%M', self.timezone) ,
												 'endDate': utcTranslator.translateFromUTC( endDate, '%Y-%m-%d_%H-%M', self.timezone)
												 })

										outputDict[dictIndex].update({element: tempDict})

								else:   # no filter append to output dictionary

									#tempDict = ({'folderName': element,
									#			 'startDate': startDate,
									#			 'endDate': endDate
									#			 })
									#Traduzione date da UTC
									tempDict = ({'folderName': element,
												 'startDate': utcTranslator.translateFromUTC( startDate, '%Y-%m-%d_%H-%M', self.timezone) ,
												 'endDate': utcTranslator.translateFromUTC( endDate, '%Y-%m-%d_%H-%M', self.timezone)
												 })

									outputDict[dictIndex].update({element: tempDict})

					self.outputJson = outputDict

				else:

					self.error = 'Nessuna cartella disponibile'

				break


			print("*** Execution time {} seconds".format(time.time() - start_time))
			logger.sendLogMsg('RECORDING_LIST', 'DEBUG', '*** Recordings List Complete in: {}'.format(time.time() - start_time))

		except KeyboardInterrupt:

			# handle Ctrl-C
			print('Cancelled by user')
			error = 'Cancelled by user'

		except Exception as ex:

			# handle unexpected script errors
			logger.sendLogMsg('RECORDING_LIST', 'ERROR', 'Unhandled error: {}'.format(ex))
			print("Unhandled error\n{}".format(ex))
			error = 'Unhandled error: {}'.format(ex)
			raise


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

		print('*** startDate, endDate: {} - {}'.format(startDate, endDate))

		return startDate, endDate


	def calcEmptyRange(self, fullPath):

		emptyBool = True

		# find if range is not empty
		for root, dirs, files in os.walk(fullPath):

			for element in files:

				if '_' in element and '-' in element and '.ts' in element: #avoid temp files

					print(element)
					#extract date from filename 004_A_03_HD_2017-07-13_12-59-00_bcad28cd7979.ts -> 2017-07-13_12-59
					dateTemp = element.split('_')[4] + '_' + element.split('_')[5].split('-')[0] + '-' + element.split('_')[5].split('-')[1] #day + '_' + time

					# find at least a file in range
					if dateTemp >= self.inputStartDate and dateTemp <= self.inputEndDate: #valid date in file

						# found
						emptyBool = False

						# stop execution
						break

		return emptyBool


	def extractDate(self, fileNameString):

		if fileNameString is not None:

			# example string 001_A_01_HD_2017-07-11_09-59-04_accc8e42ea8c -> 2017-07-11_09-59
			# extract date + hour + minutes
			#result = fileNameString.split('_')[4] + ' ' + fileNameString.split('_')[5].split('-')[0] + ':' + fileNameString.split('_')[5].split('-')[1]
			result = fileNameString.split('_')[4] + '_' + fileNameString.split('_')[5].split('-')[0] + '-' + fileNameString.split('_')[5].split('-')[1]
			return result


def main():

	# input parameters
	params = {'startDate': '2018-02-14_15-57',
			  'endDate': '2018-02-14_15-59',
			  'quality': 'HD'}  # -1,-1

	newObjRecordingList = recordingsList(params)
	print(newObjRecordingList.outputJson)

if __name__=="__main__":
	main()

'''

	params = {'startDate': '2017-09-04_12-43',
			  'endDate': '2017-09-04_12-53',
			  'quality': 'HD'}  # -1,-1

	params = {'startDate': '2017-07-14_10-00',
			  'endDate': '2017-07-14_11-00',
			  'quality': 'HD'}  # -1,-1
'''