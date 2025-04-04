#!/usr/bin/python

'''
Author: Michele Sarchioto
Date: 07/07/2017
Notes: New dirs structure
Added Async History Delete
'''


import os
import module.pyLogger
import xml.etree.ElementTree as ET
import time
import module.globalvars
import module.ntpCheckModule
from operator import itemgetter, attrgetter
import shutil
import json
import requests
import psutil
import datetime
import subprocess

#init pyLogger
logger = module.pyLogger.pyLoggerClass()


def getSlotVarsFromXML():

	confPath = module.globalvars.NEVIS_CONFIG_XML       # '/nevisApp/conf/config.xml'
	dirRootPath = '/nevis/' # default value
	slotCleanerType = 'solar' # default value
	slotDepthListPath = '/nevis_app/nevis_latest/conf/generated/slot_depth_list.json'
	urlRecordings = 'http://10.28.0.56:8080/recList/completeList'
	ntpServer = ''

	tree1 = ET.parse(confPath)
	root1 = tree1.getroot()

	for child in root1:
		if child.get('key') == 'path.registrazioni':
			fileName = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** path.registrazioni: {} - {}'.format(fileName, child.text))
			print('*** path.registrazioni: {} - {}'.format(fileName, child.text))

		if child.get('key') == 'video.maxMinutes':
			maxMinutes = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** video.maxMinutes: {} - {}'.format(maxMinutes, child.text))
			print('*** video.maxMinutes: {} - {}'.format(maxMinutes, child.text))

		if child.get('key') == 'video.slotCleaner.type':
			slotCleanerType = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** video.slotCleaner.type: {} - {}'.format(slotCleanerType, child.text))
			print('*** video.slotCleaner.type: {} - {}'.format(slotCleanerType, child.text))

		if child.get('key') == 'path.slotDepthList':
			slotDepthListPath = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** path.slotDepthListPath: {} - {}'.format(slotDepthListPath, child.text))
			print('*** path.slotDepthList: {} - {}'.format(slotDepthListPath, child.text))

		if child.get('key') == 'ws.endpoint.local.recordings':
			urlRecordings = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** path.urlRecordings: {} - {}'.format(urlRecordings, child.text))
			print('*** urlRecordings: {} - {}'.format(urlRecordings, child.text))

		# MS - fix ntp 20190508
		if child.get('key') == 'path.camsConfJson':
			camsConfPath = child.text
			# print('*** camsConfPath: {}'.format(camsConfPath))

			with open(camsConfPath, 'r') as camsConfFile:
				tempDict = json.load(camsConfFile)
				if 'NTPServer' in tempDict:
					ntpServer = tempDict['NTPServer']

	return fileName, int(maxMinutes), slotCleanerType, slotDepthListPath, urlRecordings, ntpServer


def main():

	logCleaner()

	maxPercentageCheck()

	slotCleaner()

	ramDiskCleaner()

	asyncHistoryCleaner()


def logCleaner():

	try:

		# get log dir path
		confPath = module.globalvars.NEVIS_CONFIG_XML       # '/nevisApp/conf/config.xml'

		logPath = '/nevis_app/nevis_latest/log/'
		logMaxDays = 7

		tree1 = ET.parse(confPath)
		root1 = tree1.getroot()

		for child in root1:

			if child.get('key') == 'path.root.log':
				logPath = child.text
				logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** path.root.log: {} - {}'.format(logPath, child.text))
				print('*** path.root.log: {} - {}'.format(logPath, child.text))

			if child.get('key') == 'log.max.days':
				logMaxDays = int(child.text)
				logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** log.max.days: {} - {}'.format(logMaxDays, child.text))
				print('*** log.max.days: {} - {}'.format(logMaxDays, child.text))

		nowTime = datetime.datetime.now()

		for root, dirs, files in os.walk(logPath):

			for element in files:

				fileStat = os.stat(logPath + element)
				fileLastModDate = fileStat.st_mtime	# epoch time

				fileLastModDateObj = datetime.datetime.fromtimestamp(fileLastModDate) # datetime obj

				daysOfDifference = (nowTime - fileLastModDateObj).days

				if daysOfDifference > logMaxDays: # if older than 10 days

					# remove file
					os.remove(logPath + element)
					logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** Removing Log: {}'.format(element))

			break


	except Exception as ex:

		# handle unexpected script errors
		logger.sendLogMsg('SLOT_CLEANER', 'ERROR', 'logCleaner - Unhandled error: {}'.format(ex))
		raise

def maxPercentageCheck():

	try:

		diskPartition, disksPercentageMax, mountPoint, disksPercentageToDelete = getSlotVarsFromXMLmaxCheck()

		diskInfo = psutil.disk_usage(mountPoint)
		percentageUsed = (float(diskInfo.total - diskInfo.free)/diskInfo.total)*100

		if percentageUsed >= disksPercentageMax:		# disk full

			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** Disk Full! Clean-up started, deleting {} percent of every queue'.format(disksPercentageToDelete))

			for root, dirs, files in os.walk(mountPoint):

				# make unique set list
				for element in dirs:  # for every subdir extract left 5

					if len(element) > 5 and '_' in str(element):    # trying to avoid non-slot folders

						for root, dirs, files in os.walk(mountPoint + element + '/'):

							if len(files) > 0:

								numberOfFiles = len(files)
								numberOfFilesToDelete = int(numberOfFiles*disksPercentageToDelete/100)

								files.sort()

								for i in range(0, numberOfFilesToDelete - 1):

									fileToRemove = mountPoint + element + '/' + files[i]
									os.remove(fileToRemove)

								break

				break

	except Exception as ex:

		# handle unexpected script errors
		logger.sendLogMsg('SLOT_CLEANER', 'ERROR', 'maxPercentageCheck - Unhandled error: {}'.format(ex))
		raise


def getSlotVarsFromXMLmaxCheck():

	confPath = module.globalvars.NEVIS_CONFIG_XML  # '/nevisApp/conf/config.xml'
	diskPartition = '/dev/sda3'
	disksPercentageMax = 95
	mountPoint = '/nevis'
	disksPercentageToDelete = 5

	tree1 = ET.parse(confPath)
	root1 = tree1.getroot()

	for child in root1:
		if child.get('key') == 'path.disk.partition':
			diskPartition = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG',
							  '*** path.disk.partition: {} - {}'.format(diskPartition, child.text))

		if child.get('key') == 'video.disks.percentage.max':
			disksPercentageMax = int(child.text)
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG',
							  '*** video.disks.percentage.max: {} - {}'.format(disksPercentageMax, child.text))

		if child.get('key') == 'path.registrazioni':
			mountPoint = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG',
							  '*** path.registrazioni: {} - {}'.format(mountPoint, child.text))

		if child.get('key') == 'video.disks.percentage.toDelete':
			disksPercentageToDelete = int(child.text)
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG',
							  '*** video.disks.percentage.toDelete: {} - {}'.format(disksPercentageToDelete, child.text))

	return diskPartition, disksPercentageMax, mountPoint, disksPercentageToDelete


def updateSlotDepthListWithNewData(slotDepthList, recListResp):

	if recListResp is not None and recListResp:		# not None and not empty

		for element in recListResp['Cams']['Cam']:

			if element['DepthRec'] != '' and element['DepthRec'] is not None and \
				element['SlotFolder'] != '' and element['SlotFolder'] is not None:

				slotDepthList[element['SlotFolder']] = int(element['DepthRec'])*60


def slotCleaner():

	try:

		start_time = time.time()

		logger.sendLogMsg('SLOT_CLEANER','DEBUG', '*** Start Slot Cleaner')

		dirRootPath, maxMinutes, slotCleanerType, slotDepthListPath, urlRecordings, ntpServer = getSlotVarsFromXML()

		runningCheckBool = False
		runningCheckBool, recListResp = slotCleanerRunningCheck(urlRecordings)

		ntpTime = module.ntpCheckModule.ntpCheckFunc(ntpServer)
		ntpTimeBool = True
		if ntpTime == 'Error':
			ntpTimeBool = False

		if runningCheckBool or ntpTimeBool: # if at least one works

			slotDepthList = {}

			# import Slot Depth List
			if os.path.isfile(slotDepthListPath):

				with open(slotDepthListPath) as dataFile:

					slotDepthList = json.load(dataFile)

			else:

				logger.sendLogMsg('SLOT_CLEANER', 'ERROR', '*** Slot Cleaner Error: No Slot Depth List file found, using default value of {} minutes'.format(maxMinutes))

			updateSlotDepthListWithNewData(slotDepthList, recListResp)

			slotDepthList['Default'] = maxMinutes
			#maxMinutes = 60 # for testing

			print('*** slotDepthList: {}'.format(slotDepthList))

			# check dir
			if dirRootPath[-1:] != '/': # check if last char is '/'
				dirRootPath = dirRootPath + '/'

			#print(dirRootPath + ' ' + maxMinutes)

			if slotCleanerType == 'solar':

				slotCleanerSolar(dirRootPath, slotDepthList, start_time)

			else:

				slotCleanerNonSolar(dirRootPath, slotDepthList)

			updateSlotDepthList(slotDepthList, slotDepthListPath)

		else:

			logger.sendLogMsg('SLOT_CLEANER', 'ERROR', '*** Slot Cleaner: nessuna registrazione in corso e ntp non attivo')

		print("*** Execution time {} seconds".format(time.time() - start_time))
		logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** Slot Cleaner Complete in: {}'.format(time.time() - start_time))

	except KeyboardInterrupt:

		# handle Ctrl-C
		print("Cancelled by user")

	except Exception as ex:

		# handle unexpected script errors
		logger.sendLogMsg('SLOT_CLEANER', 'ERROR', 'Unhandled error: {}'.format(ex))
		print("Unhandled error\n{}".format(ex))
		raise


def slotCleanerRunningCheck(urlRecordings):

	runningCheckBool = False

	resp = requests.get(urlRecordings)
	resp = json.loads(resp.text)

	numOfRecordings = 0

	# find number of "Running" and not running streams

	if resp['Cams'] is not None:

		for element in resp['Cams']['Cam']:

			if element['Status'] == 'Running':

				runningCheckBool = True
				break

	return runningCheckBool, resp


def slotCleanerSolar(dirRootPath, slotDepthList, start_time):


	start_time = int(str(start_time).split('.')[0])     # remove decimal
	maxSeconds = int(slotDepthList['Default']) * 60
	timeToCompare = start_time - maxSeconds             # maxSeconds ago

	for root, dirs, files in os.walk(dirRootPath):

		# make unique set list
		for element in dirs:  # for every subdir extract left 5

			if len(element) > 5 and '_' in str(element) or 'discarded' in str(element):    # trying to avoid non-slot folders

				for root, dirs, files in os.walk(dirRootPath + element + '/'):

					if len(files) == 0 or files is None:  # delete forlder if empty

						deleteDir(dirRootPath + element + '/')      # delete dir if empty
						if element in slotDepthList:
							slotDepthList.pop(element)                # remove element from Depth List

					else:

						# calc time to compare for the particular slot
						if element in slotDepthList:

							maxSeconds = int(slotDepthList[element]) * 60
							timeToCompare = start_time - maxSeconds

						else:  # else go default

							maxSeconds = int(slotDepthList['Default']) * 60
							timeToCompare = start_time - maxSeconds


						for singleFile in files:           # delete old files

							fileStat = os.stat(dirRootPath + element + '/' + singleFile)  # last file written
							fileLastModDate = str(fileStat.st_mtime).split('.')[0]

							if int(fileLastModDate) < timeToCompare:        # file is too old: delete

								logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** Removing File: {}'.format(singleFile))
								print('*** Removing File: {}'.format(singleFile))

								filePathToDelete = dirRootPath + element + '/' + singleFile

								os.remove(filePathToDelete)

		break


def slotCleanerNonSolar(dirRootPath, slotDepthList):

	listDirs = []
	setDirs = []  # set = list of unique values
	arrayDirs = []
	maxMinutes = 0

	for root, dirs, files in os.walk(dirRootPath):

		# make unique set list
		for element in dirs:  # for every subdir extract left 5

			if len(element) > 5 and '_' in str(element):
				listDirs.append(element[:3])

		setDirs = set(listDirs)
		#print('*** setDirs: {}'.format(setDirs))

		setDirs = list(setDirs)  # change type back to list to be indexable

		# Create empty array to separate files in groups, based on their folder
		if len(setDirs) != 0 and setDirs is not None:

			for index in range(len(setDirs)):

				arrayDirs.append([])  # append empty list

				for element in dirs:

					if str(setDirs[index]) in str(element):
						arrayDirs[index].append(element)

				#print('*** arrayDirs: {}'.format(arrayDirs))

		# separate files into groups, then sort and delete
		if len(arrayDirs) != 0 and arrayDirs is not None:

			for singleGroup in arrayDirs:

				#print('*** singleGroup: {}'.format(singleGroup))

				tempFileList = []
				maxMinutes = 0

				# walk all directories
				for singleDir in singleGroup:

					#print('*** singleDir: {}'.format(singleDir))

					for root, dirs, files in os.walk(dirRootPath + singleDir + '/'):

						if len(files) == 0 or files is None:  # delete forlder if empty

							deleteDir(dirRootPath + '/' + singleDir + '/')
							if element in slotDepthList:
								slotDepthList.pop(singleDir)  # remove element from Depth List

						else:

							for singleFile in files:
								singleFilePath = dirRootPath + singleDir + '/' + singleFile  # full path
								singleFile = singleFile[12:]
								tempFileList.append([singleFile, singleFilePath])

					# calc highest maxMinutes value
					if singleDir in slotDepthList:

						if element in slotDepthList:

							maxMinutesTemp = int(slotDepthList[singleDir])
							if maxMinutesTemp > maxMinutes:
								maxMinutes = maxMinutesTemp

						else:  # else go default

							maxMinutesTemp = int(slotDepthList['Default'])
							if maxMinutesTemp > maxMinutes:
								maxMinutes = maxMinutesTemp

					#print('*** tempFileList: {}'.format(tempFileList))

				numTotalFiles = len(tempFileList)

				# sort and delete
				if numTotalFiles > 0:

					# sort list by filename
					tempFileList = sorted(tempFileList, key=itemgetter(0))  # sort by first column
					#print('*** tempFileList len + sorted: {} - {}'.format(len(tempFileList), tempFileList))

					# delete temp list if files are more than limit
					if numTotalFiles > maxMinutes:  # if there are more than maxMinutes files in dir

						#print('*** START DELETE')
						numFilesToDelete = numTotalFiles - maxMinutes

						for i in range(0, numFilesToDelete):  # delete files

							#print(str(i) + ' ' + str(tempFileList[i][1]))  # tempFileList[i][1] = full path

							logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** Removing File: {}'.format(tempFileList[i]))
							print('*** Removing File: {}'.format(tempFileList[i][1]))

							os.remove(tempFileList[i][1])

		break


def updateSlotDepthList(slotDepthList, slotDepthListPath):

	with open(slotDepthListPath, 'w+') as outputFile:

		json.dump(slotDepthList, outputFile, indent=4, sort_keys=True)


def ramDiskCleaner():

	try:

		start_time = time.time()

		logger.sendLogMsg('SLOT_CLEANER','DEBUG', '*** Start Ram Disk Cleaner')

		ramDiskPath, waitSeconds, dirRecordingPath, discardedPath = getRamdiskVarsFromXML()

		# check dir
		if dirRecordingPath[-1:] != '/': # check if last char is '/'
			dirRecordingPath = dirRecordingPath + '/'

		if ramDiskPath[-1:] != '/': # check if last char is '/'
			ramDiskPath = ramDiskPath + '/'

		for root, dirs, files in os.walk(ramDiskPath):

			for singleDir in dirs:

				# dir last modified date
				fullPath = ramDiskPath + singleDir
				#print('*** fullPath: {}'.format(fullPath))

				statinfo = os.stat(fullPath)
				lastModDate = statinfo.st_mtime

				if (float(lastModDate) + waitSeconds*5) < time.time():  # if directory modified date > 5 minutes ago, look for content

					for root, dirs, files in os.walk(fullPath):

						# find matching dir in recording path
						if os.path.exists(dirRecordingPath + singleDir):

							if files is not None: # delete dir if empty

								for singleFile in files:

									fullFilePath = ramDiskPath + singleDir + '/' + singleFile
									slotPath = ramDiskPath + singleDir + '/'

									newFileName, deleteFlag, naFlag = checkFileFromRamdisk(singleFile, slotPath, fullFilePath)

									if deleteFlag:		# delete file

										os.remove(fullFilePath)

									elif naFlag: 		# move to discarde

										# check if discarded folder exists
										if not os.path.exists(discardedPath):
											os.makedirs(discardedPath)

										shutil.move(fullFilePath, discardedPath + newFileName)

									else: 				# move files to disk

										shutil.move(fullFilePath, dirRecordingPath + singleDir + '/' + newFileName)
						else:

							deleteDir(fullPath)

						break

			break

		print("*** Execution time {} seconds".format(time.time() - start_time))
		logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** Ram Disk Cleaner Complete in: {}'.format(time.time() - start_time))

	except KeyboardInterrupt:

		# handle Ctrl-C
		print("Cancelled by user")

	except Exception as ex:

		# handle unexpected script errors
		logger.sendLogMsg('SLOT_CLEANER', 'ERROR', 'Unhandled error: {}'.format(ex))
		print("Unhandled error\n{}".format(ex))
		raise


def getRamdiskVarsFromXML():

	confPath = module.globalvars.NEVIS_CONFIG_XML
	ramDiskPath = '/mnt/ramdisk/' # default value
	waitSeconds = 0
	dirRecordingPath = ''
	discardedPath = ''

	tree1 = ET.parse(confPath)
	root1 = tree1.getroot()

	for child in root1:

		if child.get('key') == 'path.ramdisk':
			ramDiskPath = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** path.ramdisk: {} - {}'.format(ramDiskPath, child.text))
			print('*** path.ramdisk: {} - {}'.format(ramDiskPath, child.text))

		if child.get('key') == 'video.Mp4Check.wait.seconds':
			waitSeconds = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** video.Mp4Check.wait.seconds: {} - {}'.format(waitSeconds, child.text))
			print('*** video.Mp4Check.wait.seconds: {} - {}'.format(waitSeconds, child.text))

		if child.get('key') == 'path.registrazioni':
			dirRecordingPath = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** path.registrazioni: {} - {}'.format(dirRecordingPath, child.text))
			print('*** path.registrazioni: {} - {}'.format(dirRecordingPath, child.text))

		if child.get('key') == 'path.discarded':
			discardedPath = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** path.discarded: {} - {}'.format(discardedPath, child.text))

	return ramDiskPath, int(waitSeconds), dirRecordingPath, discardedPath


def checkFileFromRamdisk(singleFile, slotPath, fullFilePath):

	tempFile = singleFile
	newFileName = None
	deleteFlag = False
	naFlag = False

	duration = None
	bitrate = None

	duration, bitrate = getFfprobeLine(fullFilePath)

	statinfo = os.stat(fullFilePath)
	size = statinfo.st_size

	durationInSeconds = 0

	if duration is not None and duration != 'N/A':
		durationInSeconds = float(duration.split(':')[0]) * 60 * 60 + float(duration.split(':')[1]) * 60 + float(
			duration.split(':')[2])  # min * 60 + seconds.cent seconds
	else:
		durationInSeconds = 0

	# check the file name to solve the *:59 problem
	tempFile = checkFileName(slotPath, tempFile)

	if size is not None and size == 0:  # delete size 0

		# delete empty file file
		deleteFlag = True
		logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** Slot Cleaner checkFileFromRamdisk: Deleting Empty File - {}'.format(fullFilePath))

	elif duration == 'N/A':  # discard

		naFlag = True
		newFileName = tempFile.split('.ts')[0] + '_NA.ts'

	else:  # move to disk

		newFileName = tempFile.split('.ts')[0] + '_' + str(int(durationInSeconds)) + '.ts'

	return newFileName, deleteFlag, naFlag


def checkFileName(slotPath, fileName):

	# sample file name 004_M_7_HD_2017-10-26_10-05-59_accc8e51aede.ts
	oldFileName = fileName
	fileNameReconstructed = fileName
	dateString = fileName.split('_')[4]
	timeString = fileName.split('_')[5]
	seconds = timeString.split('-')[2]

	dateTimeObj = datetime.datetime.strptime(dateString + '_' + timeString, '%Y-%m-%d_%H-%M-%S')

	if seconds == '59' or seconds == '58':

		# reset seconds and add a minute
		fileNameReconstructed = fileName
		dateTimeObj = dateTimeObj.replace(second=0, microsecond=0)
		timeDelta = datetime.timedelta(minutes=1)
		dateTimeObj += timeDelta

		# timeReadable = datetime.datetime.strptime('%Y-%m-%d_%H-%M-%S', dt)
		timeReadable = dateTimeObj.strftime('%Y-%m-%d_%H-%M-%S')

		fileNameReconstructed = '_'.join(fileName.split('_')[0:4]) + '_' + timeReadable + '_' + fileName.split('_')[-1]

		# move file (change name)
		#shutil.move(slotPath + oldFileName, slotPath + fileNameReconstructed)

	return fileNameReconstructed


def getFfprobeLine(filename):

	outDuration = None
	outBitrate = None

	result = subprocess.Popen(["ffprobe", filename], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	ffprobeLine = [x for x in result.stdout.readlines() if (("Duration" in x) or ("bitrate" in x))]

	# sample output   "Duration: 00:00:44.83, start: 0.000000, bitrate: 263 kb/s"

	if ffprobeLine:
		ffprobeLine = ffprobeLine[0].replace(' ','') # remove spaces
		ffprobeLineArray = ffprobeLine.split(',')

		for element in ffprobeLineArray:

			if 'Duration'.lower() in element.split(':')[0].lower():
				outDuration = element.split('Duration')[1]
				outDuration = outDuration[1:]

			if 'bitrate'.lower() in element.split(':')[0].lower():
				outBitrate = element.split(':')[1]
				outBitrate = outBitrate.split('kb')[0] + 'kb/s'

	return outDuration, outBitrate


def deleteDir(dirToDelete):

	shutil.rmtree(dirToDelete)
	print('*** Deleting Empty Directory: {}'.format(dirToDelete))
	logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** Deleting Empty Directory: {}'.format(dirToDelete))


def getAsyncVarsFromXML():

	confPath = module.globalvars.NEVIS_CONFIG_XML
	expireSeconds = 3600  # default value 1 hour
	historyPath = '/nevis/public/history/'

	tree1 = ET.parse(confPath)
	root1 = tree1.getroot()

	for child in root1:

		if child.get('key') == 'video.asyncHistory.expire.seconds':
			expireSeconds = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** expireSeconds: {} - {}'.format(expireSeconds, child.text))
			print('*** expireSeconds: {} - {}'.format(expireSeconds, child.text))

		if child.get('key') == 'path.registrazioni.storico':
			historyPath = child.text
			logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** expireSeconds: {} - {}'.format(historyPath, child.text))
			print('*** expireSeconds: {} - {}'.format(historyPath, child.text))

	return expireSeconds, historyPath


def asyncHistoryCleaner():

	try:

		logger.sendLogMsg('SLOT_CLEANER','DEBUG', '*** Start Async History Cleaner')

		expireSeconds, historyPath = getAsyncVarsFromXML()
		start_time = time.time()

		# check dir
		if historyPath[-1:] != '/': # check if last char is '/'
			historyPath = historyPath + '/'

		# examnine files if they are older than today - expireSeconds, delete it
		for root, dirs, files in os.walk(historyPath):

			for singleFile in files:

				fullPath = historyPath + singleFile

				statinfo = os.stat(fullPath)  # file stats
				lastModDate = str(statinfo.st_mtime).split('.')[0]

				if (float(lastModDate) + int(expireSeconds)) < start_time:  # files are older than 1 hour, delete it

					os.remove(fullPath)
					logger.sendLogMsg('SLOT_CLEANER', 'DEBUG', '*** asyncHistoryCleaner Removing File: {}'.format(fullPath))
					print('*** asyncHistoryCleaner Removing File: {}'.format(fullPath))

			break

	except Exception as ex:

		# handle unexpected script errors
		logger.sendLogMsg('SLOT_CLEANER', 'ERROR', 'Unhandled error: {}'.format(ex))
		print("Unhandled error\n{}".format(ex))
		raise

if __name__=="__main__":
	main()