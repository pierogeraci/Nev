import os
import sys, traceback
import time
import datetime
import shutil
from distutils.dir_util import copy_tree
import subprocess
from threading import Thread
import LocalData as LocalData
import shlex
import globalvars
import logging
import logging.handlers
import socket
import numpy as np
import Queue

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# create a file handler
handler = logging.FileHandler('/nevis_app/nevis_latest/log/nevis_multicast.log')
handler.setLevel(logging.INFO)

# create a logging format
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)

# add the handlers to the logger
logger.addHandler(handler)

class forward(object):

	def __init__(self, params={}):
		self.url=params["url"]
		self.sessionId=params["sessionId"]
		self.slotId=params["slotId"]
		self.ipMulticast=params["ipMulticast"]
		self.videoSourceId=params["videoSourceId"]
		self.ip=params["ip"]
		self.model=params["model"]
		self.vendor=params["vendor"]
		self.port=params["port"]
		self.expire=params["expire"]
		self.error=""
		self.queue = params["queue"]

	def checkPort(self):
		try:
			#logger.info("len(LocalData.multicast)->")
			lenMulti=len(LocalData.multicast)
		except KeyError:
			#logger.info("==========LocalData e vuoto")
			return 0
		else:
			if len(LocalData.multicast) > 0:
				#logger.info("==========IL MULTICAST E ATTIVO")
				for item in LocalData.multicast:
					if str(self.slotId) == item:
						#logger.info("============E GIA ATTIVO UN MULTICAST SU QUESTA SLOT/CAMERA !!!!======")
						return 2
					else:
						if str(self.port) == LocalData.multicast[item]['port']:
							#logger.info("============LA PORTA E STATA GIA UTILIZZATA, CAMBIARE PORTA !!!!======")
							return 1
			else:
				#logger.info("==========IL MULTICAST NON E ATTIVO")
				return 0
			return 0

	def randomPort(self):
		test =''
		return test

	def execute(self):
		try:
			num = np.random.randint(60000,65535)
			if not self.port:
				port = str(num)
			else:
				if self.checkPort() == 0:
					#logger.info("LA PORTA DEL SERVER E LIBERA")
					port = self.port
				elif self.checkPort() == 1:
					#logger.info("LA PORTA DEL SERVER E OCCUPATA")
					port = str(num)
				elif self.checkPort() == 2:
					#logger.info("C E GIA UN MULTICAST ATTIVO PER QUESTA CAMERA")
					return
			if not self.expire:
				expire = int(globalvars.NEVIS_IS_MULTICAST_EXPIRE)*60
			else:
				expire = int(self.expire)*60

			#startDate =  str(time.time()).split('.')[0] + '000'
			#endDate = str(time.time() + int(expire)).split('.')[0] + '000'
			startDate = time.strftime('%Y-%m-%d_%H-%M-%S', time.localtime())
			endDate = time.strftime('%Y-%m-%d_%H-%M-%S', time.localtime(time.time() + int(expire)))

			status = '1'
			# ffmpeg -re -i "rtsp://10.28.0.52/axis-media/media.amp?resolution=1280x720&framerate=15&videomaxbitrate=1000&audio=0" -vcodec copy -f mpegts udp://236.0.0.1:2000
			udp_url = "udp://"+self.ipMulticast+":"+port+"/"+self.videoSourceId
			url = self.url.replace("\\",'')
			cmd = 'ffmpeg -re -i "' + url + '" -vcodec copy -f mpegts "' + udp_url + '"'
			proc = subprocess.Popen(shlex.split(cmd))
			logger.info('MULTICAST | START CAM | %s', self.slotId)
			#data={"videoSourceId": self.videoSourceId,"ip":self.ip,"vendor":self.vendor,"model":self.model,"startDate":startDate,"endDate":endDate,"port":port,"status":status,"pid":proc.pid}
			data={"videoSourceId": self.videoSourceId,"urlMulticast":udp_url,"startDate":startDate,"endDate":endDate,"pid":proc.pid,"port":port,"status":status}
			datajsonout = {"videoSourceId": self.videoSourceId, "urlMulticast": udp_url, "startDate": startDate,
					"endDate": endDate, "pid": proc.pid}
			proc_thread = Thread(target=proc.communicate, name=self.slotId)
			proc_thread.start()
			LocalData.multicast[self.slotId] = data
			self.queue.put(datajsonout)

			proc_thread.join(int(expire))
			if proc_thread.is_alive():
				try:
					logger.info('MULTICAST | KILL CAM | %s', self.slotId)
					proc.kill()
					#LocalData.multicast=LocalData.multicast-1
					logger.info('MULTICAST | DEL CAM | %s', LocalData.multicast[self.slotId])
					del LocalData.multicast[self.slotId]
					logger.info('MULTICAST | END | Processo #%d MULTICAST terminato dopo %f secondi' % (proc.pid, expire))
				except OSError, e:
					logger.info('MULTICAST | ERRORE:', e)
		except Exception as e:
			logger.info('MULTICAST | ERRORE Exception:', e)
			traceback.print_exc(file=sys.stdout)
			self.error=e