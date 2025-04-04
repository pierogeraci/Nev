#!/usr/bin/python

from SocketServer import ThreadingMixIn
import threading
import thread
import argparse
import re
import cgi
import json
import sys
import traceback
import datetime
import Queue
import os
import time
import csv
import module.globalvars
import module.utility
import module.config
import module.LocalData as LocalData
import logging
import logging.handlers
from flask import Flask, jsonify, abort, make_response, request


# VARIABLES #########################################################

webAppName = 'restService'
app = Flask(webAppName)     # global app declaration
#commit_t = thread.start_new_thread(committer, ()) # commit thread

#portNumber = 8881

# response codes
rc_bad_request = 400
rc_ok = 200
rc_internal_server_error = 500

# LOGGER START ######################################################

fileConfig = module.globalvars.NEVIS_CONFIG_INI #  '/nevis_app/nevis_latest/conf/config.ini'
module.config.GetConfiguration(fileConfig)

formatter = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
handler = logging.handlers.TimedRotatingFileHandler(module.globalvars.LOG_FOLDER + "/log_manager_flask.log", when="midnight", backupCount=30)
handler.setFormatter(formatter)
logger = logging.getLogger()
logger.addHandler(handler)
logger.setLevel(logging.INFO)
logger.info("Log Manager started...")

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

@app.route('/addlog', methods=['POST'])
def addLogFunc():

	try:
		response = None
		responseCode = rc_ok  # default ok

		print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'error': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			jsondata = request.json

			if len(jsondata["log"]):    # if there is something in the log

				logServer.send_to_file(jsondata)
				alarmServer.send_to_file(jsondata) #Added by Luca Galati 28/02/2018 - Implementation for Alarms
				responseCode = rc_ok
				response = {'status': 'OK'}

			else:
				responseCode = rc_bad_request

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))
		response = {'status': 'KO',
					'error': 'Errore metodo: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error


class log_server():
	"""docstring for server_log."""
	def __init__(self):
		self.last_sent = datetime.datetime.now()
		self.jsondata={
			"process":"",
			"msg_type":"",
			"log":[]
		}
		self.csv_columns={}
		self.csv={}
		self.filesDict={}  # added by Michele Sarchioto, check for null chars - 23/08/2017


	def commit(self):
		for type in self.csv.keys():
			if not self.csv[type].empty():
				print("Committing " + type + "...")
				folder = module.globalvars.LOG_FOLDER
				now = datetime.datetime.now().strftime('%Y%m%d')
				filename = "LOG_"+ type + "_" + now + ".csv"
				output_file = folder + "/" + filename

				# added by Michele Sarchioto, check for null chars - 23/08/2017
				# this part will check for NUL bytes (\0) in csv files, just the first time it opens it

				if filename not in self.filesDict:
					self.filesDict.update({filename:False})

				if self.filesDict[filename] == False:        # false value = file not checked yet
					if os.path.isfile(output_file):
						self.checkForNulValues(output_file)
						self.filesDict[filename] = True
				# end added part by Michele Sarchioto

				header=False
				if not os.path.isfile(output_file):
					header=True

				file = open(output_file,'a') #open file
				csvwriter = csv.DictWriter(file, delimiter=',', lineterminator='\n', fieldnames=self.csv_columns[type]) #set csv writing settings
				if header==True:
					csvwriter.writeheader() #write csv headings
				while not self.csv[type].empty():
					row=self.csv[type].get()
					row=_parseJSON(row)
					#print row
					try:
						csvwriter.writerow(row)
					except Exception as e:
						logger.error(type)
						logger.error(row)
						logger.error(e,exc_info=True)
					self.csv[type].task_done()
				file.close()


	def send_to_file(self, jsondata):

		try:

			process=jsondata["process"]
			type=jsondata["msg_type"]
			log=jsondata["log"]
			msg_log={"TYPE":type}
			addcolumns=False

			if process not in self.csv.keys():

				self.csv[process]=Queue.Queue()
				self.csv_columns[process]=list()
				self.csv_columns[process].append("TYPE")
				addcolumns=True

			for key, value in log.items():

				msg_log[key]=value

				if addcolumns==True:
					self.csv_columns[process].append(key)
					#print('*** appended to file csv')

			self.csv[process].put(msg_log)

		except Exception as e:
			logger.error(e,exc_info=True)
			#print datetime.datetime.now()
			#traceback.print_exc(file=sys.stdout)


	# added by Michele Sarchioto, NUL check
	def checkForNulValues(self, output_file):      # open a file and re-write it
		fi = open(output_file, 'rb')
		data = fi.read()
		fi.close()
		fo = open(output_file, 'wb')
		fo.write(data.replace('\x00', ''))        # replace null values
		fo.close()

#Added by Luca Galati 28/02/2018 - Implementation for Alarms
class AlarmServer(object):
	"""docstring for AlarmServer."""
	
	def __init__(self):
		self.alarmsQueue = Queue.Queue()
		self.init = True
		self.outputFile = module.globalvars.NEVIS_SERVICE_FOLDER + "/alarms.json"
		self.jsonObject = {
							"license": 0, 
							"confDisks": 0, 
							"disks": 0, 
							"archive": 0, 
							"nevisEngine": 0
							}
	
	def commit(self):
		try:
			if self.init :
				#print('Initializing file ' + self.outputFile)
				logger.info('Initializing file ' + self.outputFile)
				self.init = False
				file = open(self.outputFile, 'w')
				json.dump(self.jsonObject, file, indent = 4)
				file.close()
			elif not self.alarmsQueue.empty() :
				
				#print("Processing incoming alarms...")
				logger.info('Processing incoming alarms...')
			
				file = open(self.outputFile, 'w') 
			
				while not self.alarmsQueue.empty():
					alarm = self.alarmsQueue.get()
					
					process = alarm['COMPONENT']
					code = alarm['CODE']
					status = alarm['STATUS']
					message = alarm['MSG']
					timestamp = alarm['TIMESTAMP']
					
					logger.info('Received Alarm [' + code + ' --> '+ str(status) + '] from process ' + process + ' with message: ' + message )
					
					if code in self.jsonObject:
						self.jsonObject[code] = status
					else :
						logger.info('Code ' + code + ' not recognized!')
						
				json.dump(self.jsonObject, file, indent = 4)
				file.close()
		except Exception as e:
			logger.error(e,exc_info=True)
			traceback.print_exc(file=sys.stdout)
		
	def send_to_file(self, jsondata):
		try:
			process = jsondata["process"]
			type = jsondata["msg_type"]
			log = jsondata["log"]
			
			if process == "NEVIS_FATAL":
				self.alarmsQueue.put(log)
				
			
		except Exception as e:
			logger.error(e,exc_info=True)

def committer():
	last_sent= datetime.datetime.now()
	while True:
		time.sleep(1)
		time_delta = (datetime.datetime.now() - last_sent).seconds
		if time_delta > 15:
			try:
				logServer.commit()
				alarmServer.commit() #Added by Luca Galati 28/02/2018 - Implementation for Alarms
				last_sent= datetime.datetime.now()
			except Exception as e:
				logger.error(e,exc_info=True)
				#print datetime.datetime.now()
				#print e
				#traceback.print_exc(file=sys.stdout)
				last_sent= datetime.datetime.now()


logServer = log_server()    # global log server declaration
alarmServer = AlarmServer() #Added by Luca Galati 28/02/2018 - Implementation for Alarms
commit_t = thread.start_new_thread(committer, ()) # commit thread

'''
commit_t = threading.Thread(target=committer) # commit thread
commit_t.start()
atexit.register(jointhread)


def jointhread():
	commit_t.join()

#should not run
if __name__=='__main__':

	commit_t = thread.start_new_thread( committer, () )

	try:

		# start Flask Server
		app.run()

	except Exception as e:
		logger.error(e,exc_info=True)
		#print datetime.datetime.now()
		#print e
		#traceback.print_exc(file=sys.stdout)
'''