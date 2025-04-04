''''
Author: Michele Sarchioto
Date: 12/05/2017
Version: 23
Notes: v23 with Ramdisk 
Notes: v26 re-introduction bitrate check
Notes: v40 removed bitrate check
Notes: v54 added sigterm handler
Notes: v56 tcp support
Notes: v61 seconds
'''


import multiprocessing
import subprocess
import pexpect
from random import randint
from time import sleep
import time
import datetime
import re
import sys
import os.path
import os
import xml.etree.ElementTree as ET
import urllib2
import json
import traceback
import shutil
import module.globalvars
import signal
import requests
import module.sigtermHelper
import logging

# Class to handle SIGTERM
class sigTermHandlerClass:

	terminate_now = False

	def __init__(self):
		signal.signal(signal.SIGINT, self.exit_handler)
		signal.signal(signal.SIGTERM, self.exit_handler)

	def exit_handler(self, signum, frame):
		print('SIGTERM CAUGHT')
		self.terminate_now = True


class ffmpegRecorder:

	# Loop Vars
	# maxLoops = 3
	previous_to_print = 'placeholder value'
	numBackup = None

	# Path and configs
	linebreak = '\n'

	#conf files
	#videoConfFile = module.globalvars.NEVIS_CONFIG_XML       # '/nevisApp/conf/config_video.xml'
	pathConfFoldersFile = '/nevisApp/conf/config_path_folders.xml'
	pathConfWs = '/nevisApp/conf/config_ws_endpoint.xml'
	recordingListFile = '/nevisApp/conf/generated/rec_list.xml'
	confFile = module.globalvars.NEVIS_CONFIG_XML           # '/nevisApp/conf/config.xml'
	
	# default values to override with conf files values
	videoPath = '/nevis/'
	logPath = '/nevisApp/log/'
	logUrl = 'http://localhost:8080/addlog'
	recListRestUrl = 'http://localhost:8080/recList/updateStatus'
	recListRestRequestStatusUrl = 'http://localhost:8080/recList/readStatus'
	ramDiskPath = '/mnt/ramdisk/'
	discardPath = '/nevis/discarded/'
	secondsDuration = 60
	cs_bitrate_counter = 10  # Covered Screen Bitrate Counter
	timeoutFfmpeg = 30
	mp4CheckWait = 60
	mp4CheckWaitAndRetry = 5
	minBitrate = 10
	maxBitrate = 2000
	uptime = ''
	recordingTimeout = 7
	durationThresholdLow = 55
	durationThresholdHigh = 65
	recListRestTimer = 10
	last_sent = datetime.datetime.now() - datetime.timedelta(seconds=10)        # this variable is initialized this way to trigger a message the first time immedatly
	missedPacketsCounter = 0
	missedPacketsLimit = 50
	missedPacketsLastUpdate = datetime.datetime.now()

	#logger
	logger = None
	inDebug = False

	# SIGTERM handler
	sigTermHandler = sigTermHandlerClass()

	def __init__(self):
		# Bitrate Check Vars
		self.logger = None
		self.importFromXML()

	def importFromXML(self):

		# open video conf
		tree1 = ET.parse(self.confFile)
		root1 = tree1.getroot()

		for child in root1:

			if child.get('key') == 'video.secondsDuration':
				self.secondsDuration = child.text
				if self.inDebug: print('*** secondsDuration: {} - {}'.format(self.secondsDuration, child.text))

			if child.get('key') == 'video.csBitrateCounter':
				self.cs_bitrate_counter = child.text
				if self.inDebug: print('*** cs_bitrate_counter: {} - {}'.format(self.cs_bitrate_counter, child.text))

			if child.get('key') == 'video.timeoutFfmpeg.seconds':
				self.timeoutFfmpeg = int(child.text)
				if self.inDebug: print('*** timeoutFfmpeg: {} - {}'.format(self.timeoutFfmpeg, child.text))

			if child.get('key') == 'video.Mp4Check.wait.seconds':
				self.mp4CheckWait = int(child.text)
				if self.inDebug: print('*** mp4CheckWait: {} - {}'.format(self.mp4CheckWait, child.text))

			if child.get('key') == 'video.Mp4Check.waitAndRetry.seconds':
				self.mp4CheckWaitAndRetry = int(child.text)
				if self.inDebug: print('*** mp4CheckWaitAndRetry: {} - {}'.format(self.mp4CheckWaitAndRetry, child.text))

			if child.get('key') == 'video.minBitrate':
				self.minBitrate = int(child.text)
				if self.inDebug: print('*** minBitrate: {} - {}'.format(self.minBitrate, child.text))

			if child.get('key') == 'video.maxBitrate':
				self.maxBitrate = int(child.text)
				if self.inDebug: print('*** maxBitrate: {} - {}'.format(self.maxBitrate, child.text))

			if child.get('key') == 'path.root.log':
				self.logPath = child.text
				if self.inDebug: print('*** logPath: {} - {}'.format(self.logPath, child.text))

			if child.get('key') == 'path.registrazioni':
				self.cs_bitrate_counter = child.text
				if self.inDebug: print('*** videoPath: {} - {}'.format(self.videoPath, child.text))

			if child.get('key') == 'ws.endpoint.local.logger':
				self.logUrl = child.text
				if self.inDebug: print('*** log Url: {} - {}'.format(self.logUrl, child.text))

			if child.get('key') == 'path.recList':
				self.recordingListFile = child.text
				if self.inDebug: print('*** recordingListFile: {} - {}'.format(self.recordingListFile, child.text))

			if child.get('key') == 'path.ramdisk':
				self.ramDiskPath = child.text
				if self.inDebug: print('*** Ram Disk Path: {} - {}'.format(self.ramDiskPath, child.text))

			if child.get('key') == 'video.recording.timeout.seconds':
				self.recordingTimeout = child.text
				if self.inDebug: print('*** Recording Timeout: {} - {}'.format(self.recordingTimeout, child.text))

			if child.get('key') == 'video.durationThresholdLow':
				self.durationThresholdLow = int(child.text)
				if self.inDebug: print('*** Duration Threshold Low: {} - {}'.format(self.durationThresholdLow, child.text))

			if child.get('key') == 'video.durationThresholdHigh':
				self.durationThresholdHigh = int(child.text)
				if self.inDebug: print('*** Duration Threshold High: {} - {}'.format(self.durationThresholdHigh, child.text))

			if child.get('key') == 'ws.endpoint.local.recListRest':
				self.recListRestUrl = child.text
				if self.inDebug: print('*** recListRest Endpoint: {} - {}'.format(self.recListRestUrl, child.text))

			if child.get('key') == 'ws.endpoint.local.recListRestRequest':
				self.recListRestRequestStatusUrl = child.text
				if self.inDebug: print('*** recListRestRequest Endpoint: {} - {}'.format(self.recListRestRequestStatusUrl, child.text))

			if child.get('key') == 'video.missedPacketsLimit':
				self.missedPacketsLimit = int(child.text)
				if self.inDebug: print('*** video.missedPacketsLimit: {} - {}'.format(self.missedPacketsLimit, child.text))

			if child.get('key') == 'path.discarded':
				self.discardPath = child.text
				if self.inDebug: print('*** path.discarded: {} - {}'.format(self.discardPath, child.text))


	def updateCameraStatus(self, num, cameraId, currentStatus, prevStatus, source):

		# calculate the time difference between last message and current
		timeDelta = (datetime.datetime.now() - self.last_sent).seconds

		if timeDelta >= self.recListRestTimer:

			currentStatus = str(currentStatus)
			prevStatus = str(prevStatus)

			num = num.split('_')[0]       # extract only the slot number

			if currentStatus!=prevStatus:
				# print "Stato cambiato per la camera " + num
				try:

					last_sent = datetime.datetime.now()
					response = self.sendStatusRecListRest(num, currentStatus, cameraId)

					if response['status'] == 'OK':

						self.sendLogMsg2('RECORDER_DEBUG', 'DEBUG', num, cameraId, 'Aggiornamento Status Camera da ' + prevStatus + ' a ' + currentStatus + ' - Source ' + source)
						prevStatus=currentStatus

					else:

						self.sendLogMsg('ERROR', num, cameraId, '*** ERROR Aggiornamento Status Camera Id: {} - {}'.format(num, response))

					return prevStatus

				except Exception as e:
					self.sendLogMsg('ERROR', num, cameraId, '*** ERROR Exception Aggiornamento Status Camera: {}'.format(str(e)))
					return prevStatus

			else:

				return prevStatus


	def checkRecListStatus(self, num, cameraId, currentStatus):      # DEPRECATED

		currentStatus = str(currentStatus)
		num = num.split('_')[0]       # extract only the slot number

		try:

			response = self.checkRecListStatusRestCall(num, cameraId)

			if response['status'] == 'OK':      # status is "response status"

				if response['Response'] != currentStatus: # recording status is different

					# send status
					response2 = self.sendStatusRecListRest(num, currentStatus, cameraId)

					if response2['status'] == 'OK':

						self.sendLogMsg2('RECORDER_DEBUG', 'DEBUG', num, cameraId, str(num) + ' - Aggiornamento checkRecListStatus a ' + currentStatus)

					else:

						self.sendLogMsg('ERROR', num, cameraId, '*** ERROR checkRecListStatus Aggiornamento Status Camera Id: {} - {}'.format(num, response2))

			else: # send message error

				self.sendLogMsg('ERROR', num, cameraId, '*** ERROR checkRecListStatus Check Status Camera Id: {} - Camera not found'.format(num))

		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			self.sendLogMsg('ERROR', num, cameraId, '*** ERROR checkRecListStatus Check Status Camera: {} - line {}'.format(e, exc_tb.tb_lineno))


	#def startCamera(self, num, cameraIp, frames, cameraId):
	def startCamera(self, num, cameraIp, cameraId, keepAliveQueue):

		self.numBackup = num
		loopVar = True  # restart loop
		rexp_ffmpeg_info = '[a-zA-Z]+=[\s0-9.:-]*\d'
		p = re.compile(rexp_ffmpeg_info)

		cameraId = cameraId.replace(':','')

		currentStatus = "Not Running"
		prevStatus = 'Init'
		secondToCheck = randint(15, 45) # check rec_list at a random second between XX:15 and XX:45

		while loopVar:

			try:

				self.sendLogMsg('DEBUG', num, cameraId, '*** Thread number: {} - Recording Start or Reset'.format(num))

				if self.sigTermHandler.terminate_now:
					break  # exit loop if SIGTERM

				timeTemp = str(time.time()).split('.')[0]
				videofilename = self.ramDiskPath + str(num) + '/' + str(num) + '_'
				#logFileName2 = self.logPath + logFileName #deprecated

				#check dirs
				if not os.path.exists(self.ramDiskPath + str(num)):
					os.makedirs(self.ramDiskPath + str(num))

				#check dirs
				if not os.path.exists(self.logPath):
					os.makedirs(self.logPath)

				# -rtsp_transport tcp
				command = 'ffmpeg -y -fflags \"+genpts\" -avoid_negative_ts \"make_zero\" -i \"' + cameraIp + '\" -c copy -map 0 -copy_unknown -f segment -segment_time ' + str(self.secondsDuration) + ' -reset_timestamps 1 -segment_atclocktime 1 -write_empty_segments 1 -strftime 1 \"' + videofilename + '%Y-%m-%d_%H-%M-%S' + '_' + cameraId + '.ts\"'


				# logger.debug('command: {}'.format(command))

				proc = pexpect.spawn(command)  # you need to define the "bash" shell otherwise the command won't work

				#self.sendLogMsg('DEBUG', num, cameraId, "{} - started pid: {} - {}".format(str(datetime.datetime.utcnow()).split('.')[0], proc.pid, command))
				if self.inDebug: print("started pid: {} - {}".format(proc.pid, command))

				# what to look for
				cpl = proc.compile_pattern_list([
					pexpect.EOF,
					'(.+)',  # looks for return carriage
					pexpect.TIMEOUT
				])

				# Init status Not Running
				#prevStatus = self.updateCameraStatus(num, cameraId, currentStatus, prevStatus, 'Init ffmpeg process')

				# Control Loop
				while True:

					if self.sigTermHandler.terminate_now:
						break  # exit loop if SIGTERM

					#keepAliveQueue.put('Keep Alive')
					i = proc.expect_list(cpl, timeout=7)

					if i == 0:  # EOF
						#currentStatus="Not Running"
						#prevStatus = self.updateCameraStatus(num, cameraId, currentStatus, prevStatus, 'EOF')
						#self.sendLogMsg('DEBUG', num, cameraId, 'the sub process {} exited'.format(num))
						if self.inDebug: print('the sub process {} exited'.format(num))

						break

					elif i == 1:

						# print unknown_line
						to_print = proc.before + proc.after
						to_print = to_print.decode('ascii')  # to avoid chars like strings like b''

						#self.sendLogMsg('DEBUG', num, cameraId, '*** Output Thread number : {} - {}'.format(num, to_print))
						if self.inDebug: print('*** Output Thread number : {} - {}'.format(num, to_print))

						# Errors check
						if str(to_print).find('503 Service Unavailable') > 0:  # Network Error
							#currentStatus="Not Running"
							#prevStatus = self.updateCameraStatus(num,cameraId, currentStatus, prevStatus, '503 Service Unavailable')
							self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - 503 Service Unavailable'.format(num))
							if self.inDebug: print('{} *** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))
							sleep(randint(3, 10))

							break

						elif str(to_print).find('end receive buffer size reported is') > 0:  # Network Error
							#currentStatus="Not Running"
							#prevStatus = self.updateCameraStatus(num,cameraId, currentStatus, prevStatus, 'Buffer Size Error')
							self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - {}'.format(num, to_print))
							if self.inDebug: print('{} *** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))
							sleep(randint(3, 10))

							break

						elif str(to_print).find('Server returned 5XX Server Error reply') > 0:  # Network Error
							#currentStatus="Not Running"
							#prevStatus = self.updateCameraStatus(num,cameraId, currentStatus, prevStatus, '5XX Server Error reply')
							self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - Server returned 5XX Server Error reply'.format(num))
							if self.inDebug: print('{} *** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))
							sleep(randint(3, 10))

							break

						elif str(to_print).find('Connection timed out') > 0 or str(to_print).find('Connection refused') > 0:  # Network Error
							currentStatus="Not Running"
							self.checkRecListStatus(num, cameraId, currentStatus)
							self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - Connection timed out'.format(num))
							if self.inDebug: print('{} *** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))
							sleep(randint(3, 10))

							break

						elif str(to_print).find('No route to host') > 0:
							currentStatus="Not Running"
							self.checkRecListStatus(num, cameraId, currentStatus)
							self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - No route to host'.format(num))
							if self.inDebug: print('{} *** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))
							sleep(randint(3, 10))

							break

						elif str(to_print).find('ramdisk') > 0 and str(to_print).find('No space left') > 0:
							currentStatus="Not Running"
							self.checkRecListStatus(num, cameraId, currentStatus)
							self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - No space left on Ramdisk'.format(num))
							if self.inDebug: print('{} *** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))
							sleep(randint(3, 10))

							break

						elif str(to_print).find('error while decoding') > 0:
							#currentStatus="Not Running"
							#prevStatus = self.updateCameraStatus(num,cameraId, currentStatus, prevStatus, 'Error while decoding bytestream')
							self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - Error while decoding bytestream'.format(num))
							if self.inDebug: print('{} *** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))
							sleep(randint(3, 10))

							# do not break

						elif str(to_print).find('NULL') > 0:
							currentStatus="Running"
							#self.sendLogMsg2('RECORDER_DEBUG', 'DEBUG', num, cameraId, 'SET RUNNING 2!!!!')
							#prevStatus = self.updateCameraStatus(num,cameraId, currentStatus, prevStatus, 'NULL error')
							# Null line, maybe lost packet
							self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - {}'.format(num, to_print))
							if self.inDebug: print('{} *** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))
							# break
							pass

						elif str(to_print).find('missed') > 0 and str(to_print).find('packets') > 0:  # Missed Packet
							self.sendLogMsg('ERROR', num, cameraId, '** ERROR thread number: {} - Missed Packets'.format(num))
							if self.inDebug: print('{} *** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))

							# check if the number of missed packet is above the limit
							self.missedPacketsCounter += 1

							# check last updated missed packets

							if (datetime.datetime.now() - self.missedPacketsLastUpdate).seconds > 60: # reset because last update was too old

								self.missedPacketsCounter = 1

							else:

								self.missedPacketsLastUpdate = datetime.datetime.now()

							if self.missedPacketsCounter > self.missedPacketsLimit:		# if too many packets are lost, reset and break

								self.missedPacketsCounter = 0

								#currentStatus="Not Running"
								self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - Error Too many Missed Packet'.format(num))
								#prevStatus = self.updateCameraStatus(num,cameraId, currentStatus, prevStatus, 'Too many Missed Packet')

								break

							# else: do not break

						else:

							#self.sendLogMsg2('RECORDER_DEBUG', 'DEBUG', num, cameraId, 'SET RUNNING 1!!!!: Value to print'.format(to_print))
							#deprecated log
							# search for regular expressions
							rexp_search = p.findall(to_print)
							#if rexp_search:
								#self.sendLogFfmpeg(rexp_search, cameraId, num)
								#currentStatus = "Running"
								#prevStatus = self.updateCameraStatus(num, cameraId, currentStatus, prevStatus, 'FFmpeg OK')

							#self.sendLogMsg2('RECORDER_DEBUG', 'DEBUG', num, cameraId, 'SET RUNNING 1!!!!')

							pass

					elif i == 2:

						currentStatus="Not Running"
						self.checkRecListStatus(num, cameraId, currentStatus)
						# timeout
						self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - TIMEOUT'.format(num))
						if self.inDebug: print('{} *** ERROR thread number: {} - TIMEOUT'.format(str(datetime.datetime.utcnow()).split('.')[0], num))

						#self.sendLogMsg('ERROR', num, cameraId, '*** ERROR thread number: {} - {}'.format(num, to_print))
						#if self.inDebug: print('*** ERROR thread number: {} - {}'.format(str(datetime.datetime.utcnow()).split('.')[0], num, to_print))

						break

					'''
					# Status Check every 60 seconds at the XX:30 mark
					if int(datetime.datetime.utcnow().second) == secondToCheck:

						self.checkRecListStatus(num, cameraId, currentStatus)
						secondToCheck = randint(15, 45) #change the random second check
					'''

				#close process
				proc.close()

			except Exception as e:

				exc_type, exc_obj, exc_tb = sys.exc_info()
				self.sendLogMsg('ERROR', num, cameraId, '*** ERROR Eccezione Registrazione thread number: {} - {} - line {}'.format(num, e, exc_tb.tb_lineno))
				return prevStatus

			finally:

				#close process
				proc.close()


	def getEmptyLog(self, type):

		if type == 'RECORDER':

			returnLog = {'process':'RECORDER',
						'msg_type':'INFO',
						'log': {'NAME': '',
							   'MACADDRESS': '',  # str
							   'TIMESTAMP': None,  # str
							   'SIZE': 'NA',  # int
							   'FILE_NAME': '',  # str
							   'DURATION': '',
							   'BIT_RATE': 'NA'  # float
							   }
						}

		elif type == 'RECORDER_DEBUG': #RECORDER_MP4_CHECK

			returnLog = {'process':'RECORDER', #RECORDER_MP4_CHECK
						'msg_type':'INFO',
						'log': {'NAME': '',
							   'MACADDRESS': '',  # str
							   'TIME': None,  # str
							   'FRAME_NUMBER': 'NA',  # int
							   'FPS': 'NA',  # int
							   'SIZE': 'NA',  # int
							   'FILE_NAME': 'NA',  # str
							   'BIT_RATE': 'NA'  # float
							   }
					   }

		return returnLog

	def sendLogFfmpeg(self, rexp_search, cameraId, slotId):

		# init log
		log = self.getEmptyLog('RECORDER')
		log['log']['MACADDRESS'] = cameraId
		log['log']['NAME'] = slotId # slot id
		log['log']['TIME'] = str(time.time()).split('.')[0] + '000' #str(datetime.datetime.utcnow()).split('.')[0]

		if self.inDebug: print('*** REXP SEARCH: {}'.format(rexp_search))

		# extract elements
		for element in rexp_search:

			temp = element.replace(' ', '')
			temp = temp.decode('ascii')

			if 'frame' in (temp.split('=')[0]):
				log['log']['FRAME_NUMBER'] = temp.split('=')[1]

			elif 'fps' in (temp.split('=')[0]):
				log['log']['FPS'] = temp.split('=')[1]

			elif 'size' in (temp.split('=')[0]):
				log['log']['SIZE'] = temp.split('=')[1]

			elif 'time' in (temp.split('=')[0]):
				log['log']['UPTIME_RECORDING'] = temp.split('=')[1]
				self.uptime = log['log']['UPTIME_RECORDING']
				#if self.inDebug: print('*** UPTIME: {} - {}'.format(self.uptime, temp.split('=')[1]))

			elif 'bitrate' in (temp.split('=')[0]):
				log['log']['BIT_RATE'] = temp.split('=')[1]
				#self.monitorBitrate(log['log']['BIT_RATE'], cameraId, slotId)

		# send Log

		#self.sendLog(log) #deprecated


	def sendLogFfmpeg2(self, slotId, cameraId, duration, bitrate, size, filename):

		# init log
		log = self.getEmptyLog('RECORDER') #RECORDER_MP4_CHECK
		log['log']['MACADDRESS'] = cameraId
		log['log']['NAME'] = slotId # slot id
		log['log']['TIMESTAMP'] = str(time.time()).split('.')[0] + '000' #str(datetime.datetime.utcnow()).split('.')[0]
		log['log']['SIZE'] = size
		log['log']['DURATION'] = duration
		log['log']['FILE_NAME'] = filename
		log['log']['BIT_RATE'] = bitrate

		# send Log
		self.sendLog(log)


	def sendLogMsg(self, type, slotName, cameraId, msgString):

		msgString.replace('=', ' ')

		if type == 'DEBUG':

			# create data
			msg = {'process':'RECORDER_DEBUG',
				'msg_type': type,
				'log': {'NAME': slotName,
					   'MACADDRESS': cameraId,  # str
					   'TIMESTAMP': str(time.time()).split('.')[0] + '000',  # str
					   'MSG': str(msgString).decode('ascii'),  # int
					   }
				}

		elif type == 'ERROR':

			msg = {'process': 'RECORDER_ERROR',
				   'msg_type': type,
				   'log': {'NAME': slotName,
						   'MACADDRESS': cameraId,  # str
						   'TIMESTAMP': str(time.time()).split('.')[0] + '000',  # str
						   'MSG': str(msgString).decode('ascii'),  # int
						   }
				   }
		else:

			if self.inDebug: print('*** ERROR Sending Log, type is: {}'.format(type))

		if msg is not None:

			self.sendLog(msg)


	def sendLogMsg2(self, process, type, slotName, cameraId, msgString):

		msgString.replace('=', ' ')

		if type in ['DEBUG', 'ERROR']:

			# create data
			msg = {'process':process,
				'msg_type': type,
				'log': {'NAME': slotName,
					   'MACADDRESS': cameraId,  # str
					   'TIMESTAMP': str(time.time()).split('.')[0] + '000',  # str
					   'MSG': msgString,  # int
					   }
			   }

		else:

			if self.inDebug: print('*** ERROR Sending Log, type is: {}'.format(type))

		if msg is not None:

			self.sendLog(msg)


	def sendLog(self, msgData):

		try:

			req = urllib2.Request(self.logUrl)

			req.add_header('Content-Type', 'application/json')
			if self.inDebug: print(json.dumps(msgData))

			response = urllib2.urlopen(req, json.dumps(msgData))
			#if self.inDebug: print(response)

		except Exception as e:
			traceback.print_exc(file=sys.stdout)
			#self.sendLogMsg2('RECORDER_DEBUG', 'DEBUG', msgData['log']['NAME'], msgData['log']['CAMERA_ID'], '*** Send Log ERROR: {}'.format(e.message))
			if self.inDebug: print('*** Send Log ERROR: {}'.format(str(e)))


	# sends the camera status in the Rec List Rest Service
	def sendStatusRecListRest(self, num, newStatus, cameraId):

		response = {'status':'KO', 'description':'Send Error'}      # pre build error

		try:

			#build message
			msgData = {'@id': num,
					   'Status' : newStatus}

			req = urllib2.Request(self.recListRestUrl)

			req.add_header('Content-Type', 'application/json')
			if self.inDebug: print(json.dumps(msgData))

			response = urllib2.urlopen(req, json.dumps(msgData))

			return json.load(response)

		except Exception as e:
			traceback.print_exc(file=sys.stdout)
			self.sendLogMsg('ERROR', num, cameraId, '*** ERROR Eccezione sendStatusRecListRest: {}'.format(str(e)))
			if self.inDebug: print('*** Send Log ERROR: {}'.format(str(e)))
			return response


	# checks the camera status in the Rec List Rest Service
	def checkRecListStatusRestCall(self,num,cameraId):

		response = {'status': 'KO', 'description': 'Send Error'}  # pre build error

		try:

			# build message
			msgData = json.dumps({"@id": num})
			headersJson = {'Content-Type': 'application/json'}

			response = requests.post(self.recListRestRequestStatusUrl, data=msgData, headers=headersJson)
			#response = urllib2.urlopen(req, json.dumps(msgData))
			# if self.inDebug: print(response)

			return json.loads(response.text)

		except Exception as e:
			traceback.print_exc(file=sys.stdout)
			self.sendLogMsg('ERROR', num, cameraId, '*** ERROR Eccezione checkRecListStatusRestCall: {}'.format(str(e)))
			if self.inDebug: print('*** Send Log ERROR: {}'.format(str(e)))
			return response


	def checkMp4Files(self, slot, cameraId, resetQueue):

		while True:

			try:

				if self.sigTermHandler.terminate_now:
					break  # exit loop if SIGTERM

				self.sendLogMsg2('RECORDER_DEBUG','DEBUG', slot, cameraId, '*** thread number: {} - START RECORDER_TS_CHECK'.format(slot))

				# wait for ffmpeg to start
				# sleep(self.mp4CheckWait*2)
				sleep(self.mp4CheckWaitAndRetry)


				# extract fiels from slot
				slotPath = self.ramDiskPath + str(slot) + '/'
				num = slot

				# check hard disk slots path
				hdPath = self.videoPath + slot + '/'

				# vars
				cameraId = cameraId.replace(':','')
				duration = None
				bitrate = None
				size = None
				lastMp4ModDate = None # last Mp4 modified dated
				currentStatus = 'Not Running'

				while True:

					if self.sigTermHandler.terminate_now:
						break  # exit loop if SIGTERM

					# check if hard disk slots exists
					if not os.path.exists(hdPath):
						os.makedirs(hdPath)

					for root, dirs, files in os.walk(slotPath):

						files.sort(reverse=True) # newest first

						lastMp4ModDate = None       # reset

						if len(files) > 1: # consider all files if they are more than 2 and if you are examining all up to the second to last file written

							tempFile = files[-1]    # examine oldest file on the folder

							duration, bitrate = self.getFfprobeLine((slotPath + tempFile))

							statinfo = os.stat(slotPath + tempFile)
							size = statinfo.st_size

							fileStat = os.stat(slotPath + files[0])  # last file written
							lastMp4ModDate = str(fileStat.st_mtime).split('.')[0]

							durationInSeconds = 0

							if duration is not None and duration != 'N/A':
								durationInSeconds = float(duration.split(':')[0]) * 60 * 60 + float(duration.split(':')[1]) * 60 + float(duration.split(':')[2])  # min * 60 + seconds.cent seconds
							else:
								durationInSeconds = 0

							# check the file name to solve the *:59 problem
							tempFile = self.checkFileName(slotPath, tempFile)

							if durationInSeconds > int(self.durationThresholdLow) and durationInSeconds < int(self.durationThresholdHigh):

								#calc bitrate
								if size is not None:

									bitrate = (((float(size) * 8)/durationInSeconds)/1000) # in kb/s
									bitrate = str(bitrate).split('.')[0] + 'kb/s'

								# send log
								self.sendLogFfmpeg2(slot, cameraId, duration, bitrate, size, tempFile)

							else:

								if duration == 'N/A':

									# warning
									if self.inDebug: print('*** File with length > {} seconds and < {} seconds'.format(self.durationThresholdLow, self.durationThresholdHigh))
									self.sendLogMsg('ERROR', slot, cameraId, 'Warning - duration N/A, move to discarded: {} - duration {}'.format(slotPath + tempFile, duration))

								else:

									# warning
									if self.inDebug: print('*** File with length > {} seconds and < {} seconds'.format(self.durationThresholdLow, self.durationThresholdHigh))
									self.sendLogMsg('ERROR', slot, cameraId, 'Warning - File too short or too long: {} - duration {}'.format(slotPath + tempFile, durationInSeconds))

							if size is not None and size == 0:		# delete size 0

								# delete empty file file
								os.remove(slotPath + tempFile)
								if self.inDebug: print( '*** Deleting empty file: {}'.format(slotPath + tempFile))
								self.sendLogMsg('ERROR', slot, cameraId, 'Deleting empty file: {}'.format(slotPath + tempFile))

								# Negative outcome, set status to "Not Running"
								currentStatus = 'Not Running'
								self.checkRecListStatus(num, cameraId, currentStatus)

							elif duration == 'N/A':					# discard

								# check if hard disk slots exists
								if not os.path.exists(self.discardPath):
									os.makedirs(self.discardPath)

								newFileName = tempFile.split('.ts')[0] + '_NA.ts'

								shutil.move(slotPath + tempFile, self.discardPath + newFileName)

								# Negative outcome, set status to "Not Running"
								currentStatus = 'Not Running'
								self.checkRecListStatus(num, cameraId, currentStatus)

							else:			# move to disk

								newFileName = tempFile.split('.ts')[0] + '_' + str(int(durationInSeconds)) + '.ts'

								# move to encrypted disk
								shutil.move(slotPath + tempFile, self.videoPath + slot + '/' + newFileName)

								# Positive outcome, set status to "Running"
								currentStatus = 'Running'
								self.checkRecListStatus(num, cameraId, currentStatus)

						elif len(files) == 0:

							# Negative outcome, set status to 'Not Running'
							currentStatus = 'Not Running'
							self.checkRecListStatus(num, cameraId, currentStatus)

						if len(files) > 2:  # if there are three or more files, do not wait

							break

						else:

							# wait and retry, check for sigterm
							for i in range(1, self.mp4CheckWaitAndRetry):  # cycle self.timeoutFfmpeg times - wait
								if self.sigTermHandler.terminate_now:
									break  # exit loop
								else:
									time.sleep(1)

						break

					# check last Mp4 modified date
					#if self.inDebug: print ('*** Check Last TS Modified Date: {} - {}'.format(lastMp4ModDate, str(time.time()).split('.')[0]))

					if lastMp4ModDate is not None:

						if (float(lastMp4ModDate)  + self.mp4CheckWait*2) < time.time(): #if last Mp4 modified date > 2 minutes ago

							self.sendLogMsg2('RECORDER_DEBUG', 'DEBUG', slot, cameraId, 'Reset FFmpeg checkMp4Files - No data for 2 minutes')
							resetQueue.put('Reset FFmpeg')

							# Negative outcome, set status to 'Not Running'
							currentStatus = 'Not Running'
							self.checkRecListStatus(num, cameraId, currentStatus)

							# wait a minute after reset, check for sigterm
							for i in range(1, self. self.mp4CheckWait):
								if self.sigTermHandler.terminate_now:
									break  # exit loop
								else:
									time.sleep(1)

			except Exception as e:

				exc_type, exc_obj, exc_tb = sys.exc_info()
				self.sendLogMsg('ERROR', num, cameraId, '*** ERROR Eccezione checkMp4Files: {} - line {}'.format(e, exc_tb.tb_lineno))


	def checkAlive(self, slot, cameraId, resetQueue, keepAliveQueue):

		if self.inDebug: print('*** Start Keep Alive')

		while True:

			try:

				sleep(self.timeoutFfmpeg)

				if not keepAliveQueue.empty():  # if there is a keep alive message

					# empty queue
					while not keepAliveQueue.empty():

						keepAliveQueue.get()

				else:
					if self.inDebug: print('*** checkAlive Alive - Reset FFmpeg')
					self.sendLogMsg2('RECORDER_DEBUG', 'DEBUG', slot, cameraId, 'Reset FFmpeg checkAlive')
					resetQueue.put('Reset FFmpeg')

			except Exception as e:

				self.sendLogMsg('ERROR', slot, cameraId, '*** ERROR Eccezione checkAlive: {}'.format(str(e)))


	def getFfprobeLine(self, filename):

		outDuration = None
		outBitrate = None

		result = subprocess.Popen(["ffprobe", filename], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		ffprobeLine = [x for x in result.stdout.readlines() if (("Duration" in x) or ("bitrate" in x))]

		# sample output   "Duration: 00:00:44.83, start: 0.000000, bitrate: 263 kb/s"

		if self.inDebug: print('*** FFprobe Line: {}'.format(ffprobeLine))

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


	def checkBitrate(self, bitrate, slot, cameraId):

		if self.inDebug: print('*** Start Check Bitrate')

		bitrate = bitrate.split('kb')[0]

		if self.inDebug: print('*** Start Check Bitrate - Value: {}'.format(bitrate))

		if int(bitrate) < self.minBitrate or int(bitrate) > self.maxBitrate:

			#covered sensor
			self.sendLogMsg2('RECORDER_DEBUG', 'DEBUG', slot, cameraId, 'Probabile Sensore Coperto')


	def checkFileName(self, slotPath, fileName):

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
			shutil.move(slotPath + oldFileName, slotPath + fileNameReconstructed)

		return fileNameReconstructed


	def runThreads(self, num, cameraIp, cameraId): # num = slot

		mp4CheckThread = None
		recordingThread = None

		try:

			# Queues
			resetQueue = multiprocessing.JoinableQueue()
			keepAliveQueue = multiprocessing.JoinableQueue()

			# Mp4 Control Thread
			mp4CheckThread = multiprocessing.Process(target=self.checkMp4Files, args=(num, cameraId, resetQueue, ))
			mp4CheckThread.start()

			keepAliveThread = multiprocessing.Process(target=self.checkAlive, args=(num, cameraId, resetQueue, keepAliveQueue, ))
			# keepAliveThread.start()   # deprecated

			while True:

				if self.sigTermHandler.terminate_now:
					break								# exit execution

				#start new thread
				#self.sendLogMsg('DEBUG', num, cameraId, '*** Start New Recording Thread')
				if self.inDebug: print('*** Start New Recording Thread')

				recordingThread = multiprocessing.Process(target=self.startCamera, args=(num, cameraIp, cameraId, keepAliveQueue, ))
				#recordingThread = multiprocessing.Process(target=self.startCamera, args=(num, cameraIp, frames, cameraId, ))
				recordingThread.start()

				for i in range(1, self.timeoutFfmpeg): # cycle self.timeoutFfmpeg times - wait
					if self.sigTermHandler.terminate_now:
						break							# exit loop
					else:
						module.sigtermHelper.sigtermHelperFunc()
						time.sleep(1)

				if self.sigTermHandler.terminate_now:
					break								# exit execution

				while True:

					#self.sendLogMsg('DEBUG', num, cameraId, '*** Enter Control Loop')
					if self.inDebug: print('*** Enter Control Loop')

					#wait 30 seconds before checking again
					for i in range(1, self.timeoutFfmpeg):  # cycle self.timeoutFfmpeg times - wait
						if self.sigTermHandler.terminate_now:
							break  # exit loop
						else:
							module.sigtermHelper.sigtermHelperFunc()
							time.sleep(1)

					if self.sigTermHandler.terminate_now:
						break							# exit execution

					# control checkmp4 thread
					if not mp4CheckThread.is_alive():

						mp4CheckThread.terminate()
						mp4CheckThread.join()

						mp4CheckThread = multiprocessing.Process(target=self.checkMp4Files, args=(num, cameraId, resetQueue,))
						mp4CheckThread.daemon = True		# this is necessary because we need to kill the father and the sons processes must follow
						mp4CheckThread.start()

					if not resetQueue.empty(): # if there is a reset message

						recordingThread.terminate() # terminate recording
						recordingThread.join()

						# empty queue
						while not resetQueue.empty():
							resetQueue.get()

						break

		except KeyboardInterrupt:
			# handle Ctrl-C
			if self.inDebug: print("Cancelled by user")

		except Exception as ex:
			# handle unexpected script errors
			if self.inDebug: print("Unhandled error\n{}".format(ex))
			self.sendLogMsg('ERROR', num, cameraId, '*** ERROR Eccezione runThreads: {}'.format(str(ex)))

		finally:

			mp4CheckThread.terminate()
			#keepAliveThread.terminate()
			recordingThread.terminate()

			mp4CheckThread.join()
			recordingThread.join()

			resetQueue.close()
			keepAliveQueue.close()


def main():

	try:

		# init vars
		recorderTest = ffmpegRecorder()
		arg1 = sys.argv[1]
		arg2 = sys.argv[2]
		arg3 = sys.argv[3]
		#arg4 = sys.argv[4]
		#arg5 = sys.argv[5] # log name, deprecated

		# init recording
		recorderTest.runThreads(arg1, arg2, arg3)
		# recorderTest.startCamera(1, 'rtsp://10.28.0.52/axis-media/media.amp?resolution=1280x720&framerate=15&videomaxbitrate=1000&audio=0', 'telecameraTest')

	except KeyboardInterrupt:
		# handle Ctrl-C
		print("Cancelled by user")
	except Exception as ex:
		# handle unexpected script errors
		#print("Unhandled error\n{}".format(ex))
		raise


def getLogPathFromXML():

	confFile = '/nevisApp/conf/config.xml'
	logPathTemp = None

	tree2 = ET.parse(confFile)
	root2 = tree2.getroot()

	for child in root2:
		if child.get('key') == 'path.root.log':
			logPathTemp = child.text

	return logPathTemp


if __name__ == "__main__":
	main()
