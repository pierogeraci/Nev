#title           :streaming.py
#description     :Streaming Module
#author          :Mario Squillace
#date            :20180725
#version         :1.4.0
#usage           :python streaming.py
#notes           :
#python_version  :2.7.9  
#==============================================================================

#import vlc
import os
import sys, traceback
import time
import shutil
from distutils.dir_util import copy_tree
import subprocess
from threading import Thread
import module.LocalData as LocalData
import shlex
#import module.globalvars
#import logging
#import logging.handlers

class forward(object):
	def __init__(self, params={}):
		#formatter = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
		#handler = logging.handlers.TimedRotatingFileHandler(module.globalvars.LOG_FOLDER + "/nevis_is.log", when="midnight", backupCount=30)
		#handler.setFormatter(formatter)
		#logger = logging.getLogger() 
		#logger.addHandler(handler)
		#logger.setLevel(logging.INFO)
		
		self.url=params["url"]
		self.urlLive=params["urlLive"]
		#self.port=params["port"]
		self.sessionId=params["sessionId"]
		self.camId=params["camId"]
		self.error=""

	def execute(self):
		try:
			url = ''
			urlLive = ''
			timeout_sec = 3600
			#instance=vlc.Instance('--sout=#standard{access=http,mux=ts,dst=:' + self.port + '}')
			#player = instance.media_player_new()
			#media=instance.media_new(self.url)
			#media.get_mrl()
			#player.set_media(media)
			#player.play()
			#print("scrivo la cartella")
			directory="/nevis/public/streaming/" + self.sessionId + '/' + self.camId
			#print("sessione: " + self.sessionId)
			if not os.path.exists(directory):
				os.makedirs(directory)
				#print("cartella scritta")
			#print("fine scrittura della cartella")
			LocalData.live=LocalData.live+1
			#print(LocalData.live)
			#copy_tree("/nevis/public/streaming/empty",directory)
			#OLD CPU 50%
			#command ="ffmpeg -i \"" + self.url + "\" -s 1280x720 -start_number 0 -hls_time 5 -hls_list_size 1 -f hls -hls_flags delete_segments " + directory + "/index.m3u8"
			#os.system(command)
			
			#ffmpeg -y \
			# -i http:// \
			# -codec copy \
			# -map 0 \
			# -f hls \
			# -hls_time 5 \
			# -hls_list_size 1 \
			# -hls_flags delete_segments \
			# /media/psf/centos/index.m3u8
			
			
			#NEW CPU 0.5% RAM 0.1% - 24/04/2017
			#cmd = 'ffmpeg -y -i ' + self.url + ' -codec copy -map 0 -f hls -hls_allow_cache 1 -hls_time 5 -hls_list_size 3 -hls_flags delete_segments \"' + directory + '/index.m3u8\"'

			#2 cmd = 'ffmpeg -y -i ' + self.url + ' -codec copy -map 0 -f hls -hls_allow_cache 1 -hls_time 5 -hls_list_size 3 -hls_flags delete_segments \"' + directory + '/index.m3u8\"'
			url = self.url
			urlLive = self.urlLive

			if urlLive != '':
				url = urlLive

			cmd = 'ffmpeg -y -i ' + url + ' -codec copy -map 0 -f hls -hls_allow_cache 1 -hls_time 3 -hls_list_size 6 -hls_flags delete_segments \"' + directory + '/index.m3u8\"'

			#print('Comando: ' + cmd)
			#proc = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
			#out, err = proc.communicate()
			proc = subprocess.Popen(shlex.split(cmd))
			print("#########START REGISTRAZIONE###########")
			proc_thread = Thread(target=proc.communicate)
			proc_thread.start()
			proc_thread.join(timeout_sec)
			""""
			if out:
				print '---->>>>>>>>>>>>>>>>START standard output of subprocess:'
				print out
			if err:
				print '---->>>>>>>>>>>>>>>>START standard error of subprocess:'
				print err
				
			print 'returncode of subprocess: ' + str(proc.returncode)
			"""
			if proc_thread.is_alive():
				try:
					proc.kill()
					shutil.rmtree(directory)
					#print "Cartella Eliminata!"
					list=LocalData.sessions[self.sessionId]
					index=list.index(self.camId)
					del list[index]
					#print "CamId eliminato!"
					LocalData.live=LocalData.live-1
					#print(LocalData.live)
					dir="/nevis/public/streaming/" + self.sessionId + '/'
					if not os.listdir(dir):
						shutil.rmtree(dir)
				except OSError, e:
					print 'Errore:' + e
				print('################Processo #%d di registrazione terminato dopo %f secondi' % (proc.pid, timeout_sec))
			
		except Exception as e:
			print ('Errore Exception:')
			traceback.print_exc(file=sys.stdout)
			self.error=e
