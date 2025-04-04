#!/usr/bin/python

import threading
import thread
import json
import sys
import datetime
import os
import time
import module.globalvars
import module.utility
import module.config
import logging.handlers
from flask import Flask, jsonify, abort, make_response, request
import ConfigParser
import json
import xmltodict
from xmljson import badgerfish as bf
from lxml.html import Element, tostring, etree
import xml.dom.minidom as xminidom


# VARIABLES #########################################################

webAppName = 'restServiceRecList'
app = Flask(webAppName)  # global app declaration
inDebug = False

# response codes
rc_bad_request = 400
rc_ok = 200
rc_internal_server_error = 500

# LOGGER START ##############d########################################

fileConfigIni = module.globalvars.NEVIS_CONFIG_INI # '/nevisApp/conf/config.ini'
module.config.GetConfiguration(fileConfigIni)

formatter_recList = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
handler_recList = logging.handlers.TimedRotatingFileHandler(module.globalvars.LOG_FOLDER + "/log_rec_list_rest.log", when="midnight",
													backupCount=30)
handler_recList.setFormatter(formatter_recList)
logger_recList = logging.getLogger()
logger_recList.addHandler(handler_recList)
logger_recList.setLevel(logging.INFO)
logger_recList.info("Log Rec List started...")


#####################################################################

def _parseJSON(obj):
	if isinstance(obj, dict):
		newobj = {}
		for key, value in obj.iteritems():
			key = str(key)
			newobj[key] = _parseJSON(value)
	elif isinstance(obj, list):
		newobj = []
		for value in obj:
			newobj.append(_parseJSON(value))
	elif isinstance(obj, unicode):
		newobj = obj.encode('utf-8')
	else:
		newobj = obj
	return newobj


@app.route('/init', methods=['POST'])
def initFunc():

	try:

		response = None
		responseCode = rc_ok  # default ok
		global tempjson

		if inDebug: print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'error': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			writeServer.sendToBuffer({'Operation': 'initJson', 'json': request.json})

			#esito = writeServer.initJson(request.json)
			responseCode = rc_ok
			response = {'status': 'OK'}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		if inDebug: print("Unhandled error\n{}".format(ex))
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO',
					'error': 'Errore metodo initFunc: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error


# udate status Init/Running/Not Running
@app.route('/updateStatus', methods=['POST'])    # {"@id" : "001", "Status" : "Running"}
def updateStatus():

	try:

		response = None
		responseCode = rc_ok  # default ok

		if inDebug: print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'error': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			jsondata = request.json

			writeServer.sendToBuffer({'Operation':'updateStatus', 'json' : jsondata})
			responseCode = rc_ok
			response = {'status': 'OK'}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		if inDebug: print("Unhandled error\n{}".format(ex))
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO',
					'error': 'Errore metodo updateStatus: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error


@app.route('/readStatus', methods=['POST'])          # {"@id" = "001"}
def readStatus():

	try:

		response = None
		responseCode = rc_ok  # default ok

		if inDebug: print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'error': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			jsondata = request.json

			responseValue = writeServer.readStatus(jsondata)

			if responseValue is not None:

				responseCode = rc_ok
				response = {'status': 'OK', 'Response' : responseValue}

			else:

				responseCode = rc_internal_server_error
				response = {'status': 'KO',
							'error': 'Errore metodo readStatus: Stato non trovato'}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		if inDebug: print("Unhandled error\n{}".format(ex))
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO',
					'error': 'Errore metodo readStatus: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error


@app.route('/updateStream', methods=['POST'])               # {"@id":"001","Ip":"10.28.0.52","Mac":"ac:cc:8e:42:ea:8c","Vendor":"axis","Model":"p3904","Profile":"HD","Url":"rtsp://10.28.0.52/axis-media/media.amp?resolution=1280x720\\&fps=15\\&videomaxbitrate=1000\\&audio=0","Status":"Running","Pid":"26370","IsOnvif":"false","SlotFolder":"001_M_01_HD"}
def updateStream():

	try:

		response = None
		responseCode = rc_ok  # default ok

		if inDebug: print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'error': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			writeServer.sendToBuffer({'Operation':'updateStream', 'json' : request.json})
			responseCode = rc_ok
			response = {'status': 'OK'}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		if inDebug: print("Unhandled error\n{}".format(ex))
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO',
					'error': 'Errore metodo updateStream: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error


@app.route('/addStream', methods=['POST'])              # {"@id":"001","Ip":"10.28.0.52","Mac":"ac:cc:8e:42:ea:8c","Vendor":"axis","Model":"p3904","Profile":"HD","Url":"rtsp://10.28.0.52/axis-media/media.amp?resolution=1280x720\\&fps=15\\&videomaxbitrate=1000\\&audio=0","Status":"Running","Pid":"26370","IsOnvif":"false","SlotFolder":"001_M_01_HD"}
def addStream():
	try:

		response = None
		responseCode = rc_ok  # default ok

		if inDebug: print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'error': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			writeServer.sendToBuffer({'Operation': 'addStream', 'json': request.json})
			responseCode = rc_ok
			response = {'status': 'OK'}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		if inDebug: print("Unhandled error\n{}".format(ex))
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO',
					'error': 'Errore metodo addStream: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error


@app.route('/deleteStream', methods=['POST'])               # {"@id":"001"}
def deleteStream():
	try:

		response = None
		responseCode = rc_ok  # default ok

		if inDebug: print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'error': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			writeServer.sendToBuffer({'Operation': 'deleteStream', 'json': request.json})
			responseCode = rc_ok
			response = {'status': 'OK'}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		if inDebug: print("Unhandled error\n{}".format(ex))
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO',
					'error': 'Errore metodo deleteStream: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error


@app.route('/completeList', methods=['GET'])
def completeList():

	listToReturn = writeServer.completeList()

	# return
	return jsonify(listToReturn)


class write_Server():
	"""docstring for server_log."""

	def __init__(self):

		self.last_sent = datetime.datetime.now()
		self.outputFile = module.globalvars.NEVIS_CONFIG_XML
		self.outputSemaphoreBlock = False
		self.bufferSemaphoreBlock = False
		self.buffer = []
		self.jsonDataInternal = {"Cams": {"Cam": []}}
		self.initComplete = False

		# functions dictionary
		self.funcDict = { 'updateStatus': self.updateStatus,
					'updateStream' : self.updateStream,
					'addStream' : self.addStream,
					'deleteStream' : self.deleteStream,
					'initJson': self.initJson}

		self.loadFromIni()

		self.loadOldFile()      # to avoid errors when apache restarts


	def loadFromIni(self):

		try:

			# vars
			sectionFolder = 'SETTINGS'
			optionFolder = 'SERVICE_FOLDER'
			sectionFile = 'THREAD_MANAGER'
			optionFile = 'REC_LIST'

			# ipmort config
			config = ConfigParser.ConfigParser()
			config.read(fileConfigIni)

			recFolder = config.get(sectionFolder, optionFolder)
			recFile = config.get(sectionFile, optionFile)

			self.outputFile = recFolder + '/' + recFile

		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			logger_recList.error('*** ERROR checkRecListStatus Check Status Camera: {} - line {}'.format(e, exc_tb.tb_lineno))


	def loadOldFile(self):

		try:

			if os.path.isfile(self.outputFile):    # if it exists, load it

				with open(self.outputFile, "rb") as f:  # notice the "rb" mode

					jsonDataInternalTemp = json.load(f)

					# reset statuses to 'Not Running'
					while True:

						if self.outputSemaphoreBlock is False:

							self.outputSemaphoreBlock = True

							if jsonDataInternalTemp['Cams'] is not None and jsonDataInternalTemp['Cams']:

								lenCams = len(jsonDataInternalTemp['Cams']['Cam'])

								for index in range(lenCams):

									jsonDataInternalTemp['Cams']['Cam'][index]['Status'] = 'Reset'

								self.jsonDataInternal = jsonDataInternalTemp

							self.outputSemaphoreBlock = False

							break

						else:

							time.sleep(0.5)

					logger_recList.info("Log Rec List: Loaded Old File")

		except Exception as e:
			self.outputSemaphoreBlock = False
			exc_type, exc_obj, exc_tb = sys.exc_info()
			logger_recList.error('*** ERROR checkRecListStatus Check Status Camera: {} - line {}'.format(e, exc_tb.tb_lineno))


	def deleteOldFile(self):

		try:

			# remove old file
			if os.path.isfile(self.outputFile):    # if it exists, delete it
				os.remove(self.outputFile)
				logger_recList.info("Log Rec List: Deleted old file")
			else:
				logger_recList.info("Log Rec List: No files to delete")

			self.initComplete = True

		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			logger_recList.error('*** ERROR checkRecListStatus Check Status Camera: {} - line {}'.format(e, exc_tb.tb_lineno))


	def initJson(self, jsondata):

		try:

			# copy in memory
			self.jsonDataInternal = jsondata

			logger_recList.info("Log Rec List: Init Complete")

		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			logger_recList.error('*** ERROR checkRecListStatus Check Status Camera: {} - line {}'.format(e, exc_tb.tb_lineno))


	def sendToBuffer(self, jsonData):

		# reset statuses to 'Not Running'
		while True:

			# check for write lock
			if self.bufferSemaphoreBlock is False:
				# lock write
				self.bufferSemaphoreBlock = True

				self.buffer.append(jsonData)
				#if inDebug: print(1)

				# lock write
				self.bufferSemaphoreBlock = False

				break

			else:

				time.sleep(0.1)


	def completeList(self):

		# force buffer write
		self.writeBuffer()

		return self.jsonDataInternal


	def writeBuffer(self):

		try:

			while True:

				# check for write lock
				if self.bufferSemaphoreBlock is False:

					# lock write
					self.bufferSemaphoreBlock = True

					while len(self.buffer) > 0:

						# extract operation
						operation = self.buffer[0]

						# log operation
						logger_recList.info('Operation: {}'.format(operation))

						try:

							parameters = operation['json']
							function = operation['Operation']
							# function pointers to correct operation
							self.funcDict[function](parameters)      # calls 'Operation' class methods and parameters

						except Exception as e:
							logger_recList.error(e, exc_info=True)
							exc_type, exc_obj, exc_tb = sys.exc_info()
							if inDebug: print('Error: {} - line {}'.format(e, exc_tb.tb_lineno))

						# deplete buffer
						self.buffer.pop(0)      # remove first element, second element becomes first

						# flush to file
						self.writeToFile()

						# lock write
					self.bufferSemaphoreBlock = False

					break

				else:

					time.sleep(0.1)

		#if inDebug: print(1)
		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			logger_recList.error('*** ERROR checkRecListStatus Check Status Camera: {} - line {}'.format(e, exc_tb.tb_lineno))


	def writeToFile(self):

		try:

			# check for write lock
			if self.outputSemaphoreBlock is False:

				# lock write
				self.outputSemaphoreBlock = True

				with open(self.outputFile, "w+") as f:
					# write to file
					json.dump(self.jsonDataInternal, f, indent=4, sort_keys=True)
					f.close()
					#logger_recList.info("Log Rec List: Init Complete")

				# release lock
				self.outputSemaphoreBlock = False

		except Exception as e:
			self.outputSemaphoreBlock = False
			exc_type, exc_obj, exc_tb = sys.exc_info()
			logger_recList.error('*** ERROR writeToFile: {} - line {}'.format(e, exc_tb.tb_lineno))


	def updateStatus(self, jsondata):       # {"@id" = "001"; "Status" = "Running"}

		for i in range(len(self.jsonDataInternal['Cams']['Cam'])):

			if self.jsonDataInternal['Cams']['Cam'][i]['@id'] == jsondata['@id']:

				self.jsonDataInternal['Cams']['Cam'][i]['Status'] = jsondata['Status']


	def readStatus(self, jsondata):         # {"@id" = "001"}

		returnValue = None

		for element in self.jsonDataInternal['Cams']['Cam']:

			if element['@id'] == jsondata['@id']:

				returnValue = element['Status']

		return returnValue


	def updateStream(self, jsondata):       # {"Operation": "updateStream", "json" : {"@id":"001","Ip":"10.28.0.52","Mac":"ac:cc:8e:42:ea:8c","Vendor":"axis","Model":"p3904","Profile":"HD","Url":"rtsp://10.28.0.52/axis-media/media.amp?resolution=1280x720\\&fps=15\\&videomaxbitrate=1000\\&audio=0","Status":"Running","Pid":"26370","IsOnvif":"false","SlotFolder":"001_M_01_HD"}}
											# {"Operation": "updateStream", "json" : {"@id":"002","Ip":"test","Mac":"test","Vendor":"test","Model":"test","Profile":"test","Url":"test","Status":"test","Pid":"test","IsOnvif":"test","SlotFolder":"test"}}
		# find and replace stream
		for i in range(len(self.jsonDataInternal['Cams']['Cam'])):

			# degub
			# print(self.jsonDataInternal['Cams']['Cam'][i])
			# print(jsondata)
			# print(jsondata['@id'])

			if self.jsonDataInternal['Cams']['Cam'][i]['@id'] == jsondata['@id']:

				self.jsonDataInternal['Cams']['Cam'][i] = jsondata

		#print(1)


	def addStream(self, jsondata):          # {'Operation': 'updateStream, json : {"@id":"001","Ip":"10.28.0.52","Mac":"ac:cc:8e:42:ea:8c","Vendor":"axis","Model":"p3904","Profile":"HD","Url":"rtsp://10.28.0.52/axis-media/media.amp?resolution=1280x720\\&fps=15\\&videomaxbitrate=1000\\&audio=0","Status":"Running","Pid":"26370","IsOnvif":"false","SlotFolder":"001_M_01_HD"}}

		# append to main json
		self.jsonDataInternal['Cams']['Cam'].append(jsondata)
		#print(1)


	def deleteStream(self, jsondata):       # {"@id":"001"}

		# find and remove stream
		for i in range(len(self.jsonDataInternal['Cams']['Cam'])):

			if self.jsonDataInternal['Cams']['Cam'][i]['@id'] == jsondata['@id']:

				self.jsonDataInternal['Cams']['Cam'].pop(i)
		#print(1)


# threaded function to commit every X seconds
def committer():

	last_sent = datetime.datetime.now()
	while True:
		time.sleep(1)
		time_delta = (datetime.datetime.now() - last_sent).seconds
		if time_delta > 5:
			try:
				writeServer.writeBuffer()
				last_sent = datetime.datetime.now()
			except Exception as e:
				logger_recList.error(e, exc_info=True)
				# print datetime.datetime.now()
				# print e
				# traceback.print_exc(file=sys.stdout)
				last_sent = datetime.datetime.now()


writeServer = write_Server()  # global log server declaration
commit_t = thread.start_new_thread(committer, ())  # commit thread

if __name__=='__main__':

	app.run()

