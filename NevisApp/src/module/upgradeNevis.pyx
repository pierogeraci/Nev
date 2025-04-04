import requests
import shutil
import time
import pyLogger
import globalvars
import json
import sys
import urllib
import os
import Queue

# define logger
upgradeNevisLogger = pyLogger.pyLoggerClass()
upgradeNevisPath = '/nevis/public/upgrade';
class forward(object):
	def __init__(self, params={}):
		# formatter = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
		# handler = logging.handlers.TimedRotatingFileHandler(module.globalvars.LOG_FOLDER + "/nevis_is.log", when="midnight", backupCount=30)
		# handler.setFormatter(formatter)
		# logger = logging.getLogger()
		# logger.addHandler(handler)
		# logger.setLevel(logging.INFO)
		self.error=""
		self.queue = params["queue"]
		if not os.path.exists(upgradeNevisPath):
			os.makedirs(upgradeNevisPath)
	def execute(self):
		try:
			datajsonout = {'msg': 'test'}
			#print result
			#upgradeNevisLogger.sendLogMsg('NEVISLOGGER', 'INFO', '*** upgradeNevis successful: {} - {}'.format(videoSourceId, imagePath))
			self.queue.put(datajsonout)
		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			result = {'status': 'ko', 'msg': '*** Exception execute: {} - {}'.format(e, exc_tb.tb_lineno)}
			#upgradeNevisLogger.sendLogMsg('NEVISLOGGER', 'ERROR', '*** Exception execute: {} - {}'.format(e, exc_tb.tb_lineno))
			self.error = e