#!/usr/bin/python
#title           :nevis_is.py
#description     :Nevis Intregration Service
#author          :Mario Squillace, Michele Sarchioto, Luca Galati
#date            :20180725
#version         :1.7.0
#usage           :python nevis_is.py
#notes           :
#python_version  :2.7.9  
#==============================================================================

from flask import Flask, jsonify, abort, make_response, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

import json
import xmltodict
import csv
import sys, os
import module.globalvars
import module.utility
import module.config
import module.concat
import module.recordingsList
import module.streaming
import module.multicast
import module.LocalData as LocalData
import module.videoAvailability
import module.utcTranslator
#import module.uptimeServerModule
import module.ntpCheckModule
import module.snapshotModule
import module.fotografiaSistemaModule
import module.database
import threading
import socket
import fcntl
import struct
import string
import random
import urllib
from xml.etree import cElementTree as ET
import shutil
import signal
import psutil
import requests
import io
import subprocess
from subprocess import check_output
import time
import os
import thread
import Queue
import re
import netaddr
import pytz
import hashlib
from datetime import datetime
import time
from ConfigParser import SafeConfigParser

from flask_jwt_extended import (
    JWTManager, jwt_required, create_access_token,
    get_jwt_identity
)
# VARIABLES #########################################################

webAppName = 'restService'
app = Flask(webAppName)
app.config['JWT_SECRET_KEY'] = '7_btJr5;\]a+e3&LdFX}vn`fUF.?AEMq?[F,D_3*RgTx,M4f6-nrJGtjp;rG%2J<'
jwt = JWTManager(app)

#Apache User
apacheUser = 'www-data'

# response codes 
rc_bad_request = 400
rc_ok = 200
rc_internal_server_error = 500
rc_validation_error = 422;

chars = string.ascii_letters + string.digits

#Limiter Start
limiter = Limiter(
	app,
	key_func=get_remote_address,
	default_limits=["24000 per day", "1000 per hour"]
)

def host_scope(endpoint_name):
	return request.host

host_limit = limiter.shared_limit("1/minute", scope=host_scope)

# MS - 20190430 - fix interfaccia bond
def get_interface_ip(ifname):
	try:
		ifname = ifname.encode('utf-8')
		s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
		ipAddress = socket.inet_ntoa(fcntl.ioctl(s.fileno(), 0x8915, struct.pack('256s', ifname[:15]))[20:24])		
		ipAddress = ipAddress + ':' + str(module.globalvars.HTTP_PORT)
		return ipAddress
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()

		print("Unhandled error while trying to determine interface IP: interface {} - error {} - line {}".format(ifname, e, exc_tb.tb_lineno))
		return None

def get_lan_ip():
	ip = socket.gethostbyname(socket.gethostname())
	if ip.startswith("127."):
		interfaces = [
			"eth0",
			"eth1",
			"eth2",
			"wlan0",
			"wlan1",
			"wifi0",
			"ath0",
			"ath1",
			"ppp0",
		]
		for ifname in interfaces:
			try:
				ip = get_interface_ip(ifname)
				break
			except IOError:
				pass
	return ip

@app.errorhandler(429)
def ratelimit_handler(e):
	return make_response(
			jsonify(msg="Server occupato. Ti invitiamo a riprovare tra %s" % e.description, status="KO")
			, 429
	)
#Limiter End

try:
	to_unicode = unicode
except NameError:
	to_unicode = str

# LUKS ############ GET SECTION #####################################
@app.route('/')
def index():
	return '[Nevisis] NeViS Integration Services'

# CAMS ##############################################################
@app.route('/stream/live', methods=['POST'])
def streamLive():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Reques
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:
			
			print request.remote_addr;
			
			jsondata = request.json
			if jsondata["videoSourceId"] == '' or jsondata["videoSourceId"] == None:
				response = {'status': 'KO', 'msg': 'Verificare campi obbligatori'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
			
			# check Session ID - Aggiunto nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
			if "sessionId" in jsondata and jsondata["sessionId"] != '':
				if not isSessionIdValid(jsondata["sessionId"]):
					response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
					responseCode = rc_bad_request
					return jsonify(response), responseCode
				else:
					sessionId = jsondata["sessionId"].split('~')[0]
			else:
				sessionId = generateRandom(10)

			check_mount = get_mount('/nevis')
			if int(check_mount) != 0:
				response = {'status': 'KO', 'msg': 'Verificare che le partizioni siano montate.'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			params = {}
			#camId = jsondata["slot"]

			slotInfo = getSlotInfoFromId(jsondata["videoSourceId"])

			getCameraListRequestJson()

			if slotInfo and LocalData.cams:
				camId = slotInfo['Id']
				#sessionId = jsondata["sessionId"]
				
				url = LocalData.cams[camId]['url']
				urlLive = LocalData.cams[camId]['urlLive']
				videoSourceId = LocalData.cams[camId]['videoSourceId']
				url = urllib.unquote(url).decode('utf8')
				urlLive = urllib.unquote(urlLive).decode('utf8')
				# print "URL - " + url
				params["url"] = url
				params["urlLive"] = urlLive
				params["videoSourceId"] = videoSourceId
				# params["sessionId"]=generateRandom(10)
				params["sessionId"] = sessionId
				params["camId"] = camId
				# Verifico se ho gia uno streaming attivo in base al sessionId e al camId
				alive = False

				if sessionId not in LocalData.sessions:
					LocalData.sessions[sessionId] = list()
					LocalData.sessions[sessionId].append(camId)

				elif camId in LocalData.sessions[sessionId]:
					alive = True
					#print("Streaming for camera " + camId + " is alive! SessionId: " + sessionId)

				elif camId not in LocalData.sessions[sessionId]:
					LocalData.sessions[sessionId].append(camId)

				if not alive:
					streaming = module.streaming.forward(params)
					d = threading.Thread(name='daemon', target=streaming.execute)
					d.setDaemon(True)
					d.start()
				responseCode = rc_ok
				#IP = get_lan_ip()
				# ':' + module.globalvars.NEVIS_IS_PORT +
				# MS - 20190430 - fix interfaccia bond
				# determine ip
				tmpJsonData = get_cams_conf()
				interfaceIp = request.host
				if 'SchedaReteNevis' in tmpJsonData and tmpJsonData['SchedaReteNevis'] is not None and tmpJsonData['SchedaReteNevis'] != '':
					tempInterfaceIp = get_interface_ip(tmpJsonData['SchedaReteNevis'])
					if tempInterfaceIp is not None:
						interfaceIp = tempInterfaceIp
				
				response = '{"status" : "OK", "videoSourceId":"' + params["videoSourceId"] + '", "url":"http://' + interfaceIp + '/streaming/' + params["sessionId"] + '/' + params["camId"] + '/index.m3u8"}'

			else:

				responseCode = rc_internal_server_error
				response = '{"status": "KO", "msg": "Camera non trovata"}'

		return jsonify(json.loads(response)), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo streamLive: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/stream/multicast/active', methods=['POST'])
def streamMulticastActive():
	try:

		response = None
		responseCode = rc_ok  # default ok

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'Esito': 'KO',
						'Descrizione': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			jsondata = request.json
			params = {}
			#camId = jsondata['slot']

			# checks
			videoSourceId = jsondata["videoSourceId"]

			ipMulticast = jsondata['ipMulticast']

			if videoSourceId is None or videoSourceId == '' or ipMulticast is None or ipMulticast == '':
				responseCode = rc_bad_request
				response = {"status": "KO", "msg": "Verificare campi obbligatori"}
				return jsonify(response), responseCode

			if videoSourceId is None or videoSourceId == None or ipMulticast is None or ipMulticast == None:
				responseCode = rc_bad_request
				response = {"status": "KO", "msg": "Verificare campi obbligatori"}
				return jsonify(response), responseCode

			# OLD
			#if jsondata["sessionId"] != '' and not jsondata["sessionId"].isalnum():
			#	response = {'status': 'KO', 'msg': 'Il campo sessionId deve essere alfanumerico'}
			#	responseCode = rc_bad_request
			#	return jsonify(response), responseCode
			# check Session ID - Aggiunto nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
			if "sessionId" in jsondata and jsondata["sessionId"] != '':
				if not isSessionIdValid(jsondata["sessionId"]):
					response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
					responseCode = rc_bad_request
					return jsonify(response), responseCode
				else:
					sessionId = jsondata["sessionId"].split('~')[0]
			else:
				sessionId = generateRandom(10)

			if jsondata["port"] != '' and not jsondata["port"].isdigit() or int(jsondata["port"]) > 65535:
				response = {'status': 'KO', 'msg': 'Il valore del campo Porta deve essere numerico e deve avere un valore non superiore a 65535'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			if jsondata["expire"] != '' and not jsondata["expire"].isdigit():
				response = {'status': 'KO', 'msg': 'Il campo expire deve essere numerico'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			#Fix per vulnerability "Data exfiltration through input parameter injection"
			if netaddr.IPAddress(jsondata['ipMulticast']).is_multicast() is False :
				response = {'status': 'KO', 'msg': 'Campo ipMulticast non valido'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
			# end checks

			slotInfo = getSlotInfoFromId(jsondata["videoSourceId"])

			if len(slotInfo) < 1:
				responseCode = rc_bad_request
				response = {"status": "KO", "msg": "Camera non trovata"}
				return jsonify(response), responseCode

			getCameraListRequestJson()

			if slotInfo['Id'] and LocalData.cams:

				slotId = slotInfo['Id']
				#sessionId = jsondata['sessionId'] rimosso nella 1.7.0
				port = jsondata['port']
				expire = jsondata['expire']

				url = LocalData.cams[slotId]['url']
				url = urllib.unquote(url).decode('utf8')
				ip = LocalData.cams[slotId]['ipAddress']
				model = LocalData.cams[slotId]['model']
				vendor = LocalData.cams[slotId]['vendor']

				params["slotId"] = slotId
				params["videoSourceId"] = videoSourceId
				params["ip"] = ip
				params["url"] = url
				params["ipMulticast"] = ipMulticast
				params["sessionId"] = sessionId
				params["model"] = model
				params["vendor"] = vendor
				params["port"] = port
				params["expire"] = expire
				# Verifico se ho gia un multicast attivo
				alive = False

				if LocalData.multicast.get(slotId) == None:

					alive = False

				elif slotId in list(LocalData.multicast.keys()):

					alive = True

					responseCode = rc_bad_request
					response = {"status": "KO", "msg": "Lo Slot che hai selezionato e gia attivo!"}

				if not alive:
					responseQueue = Queue.Queue()
					params["queue"] = responseQueue
					multicast = module.multicast.forward(params)

					d = threading.Thread(name='daemon', target=multicast.execute)
					d.setDaemon(True)
					d.start()

					# get response, waits for data
					multicastResponse = responseQueue.get()
					multicastResponse["status"] = "OK"			# add status OK

					responseCode = rc_ok
					response = multicastResponse

			else:

				responseCode = rc_bad_request
				response = {"status": "KO", "msg": "Camera non trovata"}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo streamMulticastActive: {} - line {}'.format(ex,
																						exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/stream/multicast/deactivate', methods=['POST'])
def streamMulticastDeactivate():
	try:
		response = None
		responseCode = rc_ok  # default ok
		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO','msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode
		else:
			jsondata = request.json

			# checks
			if jsondata["videoSourceId"] == '' or jsondata["videoSourceId"] == None:
				response = {'status': 'KO', 'msg': 'Verificare campi obbligatori'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			# OLD
			#if jsondata["sessionId"] != '' and not jsondata["sessionId"].isalnum():
			#	response = {'status': 'KO', 'msg': 'Il campo sessionId deve essere alfanumerico'}
			#	responseCode = rc_bad_request
			#	return jsonify(response), responseCode
			# Check Session ID - Aggiunto nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
			if "sessionId" in jsondata and jsondata["sessionId"] != '':
				if not isSessionIdValid(jsondata["sessionId"]):
					response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
					responseCode = rc_bad_request
					return jsonify(response), responseCode
				else:
					sessionId = jsondata["sessionId"].split('~')[0]
			else:
				sessionId = generateRandom(10)
			# end checks

			slotInfo = getSlotInfoFromId(jsondata["videoSourceId"])
			if len(slotInfo) < 1:
				responseCode = rc_bad_request
				response = {"status": "KO", "msg": "Camera non trovata"}
				return jsonify(response), responseCode

			getCameraListRequestJson()

			if slotInfo and LocalData.cams:
				slotId = slotInfo['Id']
				#sessionId = jsondata['sessionId'] rimosso nella 1.7.0
				if LocalData.multicast.get(slotId) == None:
					responseCode = rc_bad_request
					response = {"status": "KO", "msg": "Non e possibile disattivare questo multicast!"}
				elif LocalData.multicast.get(slotId):
					os.kill(LocalData.multicast[slotId]['pid'], signal.SIGTERM)
					#print('MULTICAST | STOP | Processo #%d' % (LocalData.multicast[slotId]['pid']))
					del LocalData.multicast[slotId]
					responseCode = rc_ok
					response = {"status": "OK", "msg": "Il multicast scelto e stato disattivato."}
			else:

				responseCode = rc_bad_request
				response = {"status": "KO", "msg": "Camera non trovata"}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo streamMulticastDeactivate: {} - line {}'.format(ex,
																							exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/stream/multicast/list', methods=['POST'])
def streamMulticastList():
	try:

		response = None
		responseCode = rc_ok  # default ok
		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			responseCode = rc_ok
			jsondata = request.json

			# checks OLD
			#if jsondata["sessionId"] != '' and not jsondata["sessionId"].isalnum():
			#	response = {'status': 'KO', 'msg': 'Il campo sessionId deve essere alfanumerico'}
			#	responseCode = rc_bad_request
			#	return jsonify(response), responseCode
			# check Session ID - Aggiunto nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
			if "sessionId" in jsondata and jsondata["sessionId"] != '':
				if not isSessionIdValid(jsondata["sessionId"]):
					response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
					responseCode = rc_bad_request
					return jsonify(response), responseCode
				else:
					sessionId = jsondata["sessionId"].split('~')[0]
			else:
				sessionId = generateRandom(10)
			# end checks

			#multicastLiveActiveDel = get_process_id("udp")
			#for mLA in multicastLiveActiveDel:
			#print mLA

			#if len(LocalData.multicast) > 0:
			#	for item in LocalData.multicast:
			#		print LocalData.multicast


					# os.kill(mLA, 9)

			#		if self.port == LocalData.multicast[item]['port']:

			response = {"status":"OK", "list": LocalData.multicast}
			#response["status"] = "OK"

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo streamMulticastList: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/stream/count', methods=['POST'])
def streamCount():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:
			streamingLiveActive = len(get_process_id("hls"))
			'''
			count = 0
			r = re.compile("^\d{3}")
			for dirpath, dirs, files in os.walk("/nevis/public/streaming/"):
				newlist = filter(r.match, dirs)
				if len(newlist) > 0:
					# print(newlist)
					count = count + len(newlist)
			'''
			responseCode = rc_ok
			response = {"status": "OK", "count": str(streamingLiveActive)}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo streamCount: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/template/insert', methods=['POST'])
def camsSettingsTemplateInsert():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			xmlFile = module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_DISCOVERY_NETWORK_LIST_CAMS_URL_PATH
			jsondata = request.json
			camera_id = jsondata['camera_id']

			if (int(camera_id) < 10):
				camera_id = '0' + str(jsondata['camera_id'])

			vendor = jsondata['vendor']
			model = jsondata['model']
			video_source_id = str(jsondata['video_source_id'])
			profiles_id = jsondata['profiles']['id']
			#print(profiles_id)
			profiles_resolution = jsondata['profiles']['resolution']
			profiles_framerate = jsondata['profiles']['framerate']
			profiles_urlTemplate = urllib.unquote(
				'rtsp://${IP_ADDRESS}' + jsondata['profiles']['urlTemplate'].replace('&', '\&')).decode('utf8')
			tree = ET.ElementTree(file=xmlFile)
			root = tree.getroot()
			findCamera = False
			profileCamera = False

			for cam in root.findall('camera'):

				if camera_id == cam.get('id'):

					findCamera = True
					#print('ID CAMERA TROVATO')
					profiles = cam.find('profiles')

					for profile in profiles.findall('profile'):

						if profiles_id == profile.find('id').text:
							profileCamera = True
							#print('ERRORE: RISPONDERE CON MESSAGGIO PROFILO CAMERA GIA PRESENTE')
							responseCode = rc_internal_server_error
							response = {"status": "KO", "msg": "Il Profilo inserito e gia presente"}

							return jsonify(response), responseCode

					if (profileCamera is False):
						#print('PROFILE NON TROVATO')
						profile_out = ET.SubElement(profiles, "profile")
						idP = ET.SubElement(profile_out, "id")
						idP.text = profiles_id
						framerate = ET.SubElement(profile_out, "framerate")
						framerate.text = str(profiles_framerate)
						resolution = ET.SubElement(profile_out, "resolution")
						resolution.text = profiles_resolution
						url_template = ET.SubElement(profile_out, "url_template")
						url_template.text = profiles_urlTemplate
						# XML Indet
						indent(root)
						# Scrivo XML
						tree.write(xmlFile, encoding="UTF-8", xml_declaration=True)
						responseCode = rc_ok
						response = {"status": "OK", "msg": "Il profilo della camera e stato aggiunto correttamente"}

						return jsonify(response), responseCode

			if (findCamera is False):
				#print('INSERIMENTO DI UNA NUOVA CAMERA')
				cam_root = ET.SubElement(root, "camera", id=str(camera_id))
				cam_root_model = ET.SubElement(cam_root, "model")
				cam_root_model.text = model
				cam_root_vendor = ET.SubElement(cam_root, "vendor")
				cam_root_vendor.text = vendor
				cam_root_video_source_id = ET.SubElement(cam_root, "video_source_id")
				cam_root_video_source_id.text = video_source_id
				cam_root_profiles = ET.SubElement(cam_root, "profiles")
				cam_root_profile = ET.SubElement(cam_root_profiles, "profile")
				idP = ET.SubElement(cam_root_profile, "id")
				idP.text = profiles_id
				framerate = ET.SubElement(cam_root_profile, "framerate")
				framerate.text = str(profiles_framerate)
				resolution = ET.SubElement(cam_root_profile, "resolution")
				resolution.text = profiles_resolution
				url_template = ET.SubElement(cam_root_profile, "url_template")
				url_template.text = profiles_urlTemplate
				# XML Indet
				indent(root)
				# Scrivo XML
				tree.write(xmlFile, encoding="UTF-8", xml_declaration=True)
				responseCode = rc_ok
				response = {"status": "OK", "msg": "La configurazione della camera e stata aggiunta correttamente"}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO','msg': 'Errore metodo camsSettingsTemplateInsert: {} - line {}'.format(ex,exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/template/update', methods=['POST'])
def camsSettingsTemplateUpdate():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			xmlFile = module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_DISCOVERY_NETWORK_LIST_CAMS_URL_PATH
			jsondata = request.json
			camera_id = jsondata['camera_id']

			if (int(camera_id) < 10):
				camera_id = '0' + str(jsondata['camera_id'])

			vendor = jsondata['vendor']
			model = jsondata['model']
			video_source_id = str(jsondata['video_source_id'])
			profiles_id = jsondata['profiles']['id']
			profiles_resolution = jsondata['profiles']['resolution']
			profiles_framerate = jsondata['profiles']['framerate']
			profiles_urlTemplate = urllib.unquote(
				'rtsp://${IP_ADDRESS}' + jsondata['profiles']['urlTemplate'].replace('&', '\&')).decode('utf8')
			tree = ET.ElementTree(file=xmlFile)
			root = tree.getroot()
			profileCamera = False

			for cam in root.findall('camera'):

				if camera_id == cam.get('id'):

					cam.find('vendor').text = vendor
					cam.find('model').text = model
					cam.find('video_source_id').text = video_source_id
					profiles = cam.find('profiles')

					for profile in profiles.findall('profile'):

						if profiles_id == profile.find('id').text:
							profileCamera = True
							#print('La configurazione della camera e stata aggiornata')
							# profile.find('id').text = profiles_id
							profile.find('resolution').text = profiles_resolution
							profile.find('framerate').text = str(profiles_framerate)
							profile.find('url_template').text = profiles_urlTemplate
							tree.write(xmlFile, encoding="UTF-8")

							responseCode = rc_ok
							response = {"status": "OK", "msg": "La configurazione della camera e stata aggiornata"}
							break

					if (profileCamera is False):
						#print('/api/v1/cams/settings/update -> Hai selezionato un profilo NON presente nella lista.')
						responseCode = rc_internal_server_error
						response = {"status": "KO", "msg": "Hai selezionato un profilo NON presente nella lista."}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO','msg': 'Errore metodo camSettingsTemplateUpdate: {} - line {}'.format(ex,exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/template/delete', methods=['POST'])
def camsSettingsTemplateDelete():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:
			xmlFile = module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_DISCOVERY_NETWORK_LIST_CAMS_URL_PATH
			jsondata = request.json
			camera_id = jsondata['camera_id']
			profiles_id = jsondata['profiles']['id']
			tree = ET.ElementTree(file=xmlFile)
			root = tree.getroot()

			for cam in root.findall('camera'):

				if camera_id == cam.get('id'):

					profiles = cam.find('profiles')

					if len(profiles.findall('profile')) == 1:

						root.remove(cam)
						tree.write(xmlFile, encoding="UTF-8")

					else:

						for profile in profiles.findall('profile'):

							if profiles_id == profile.find('id').text:
								profiles.remove(profile)
								tree.write(xmlFile, encoding="UTF-8")

			responseCode = rc_ok
			response = {"status": "OK", "msg": "La configurazione della camera e stata cancellata"}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo camSettingsTemplateDelete: {} - line {}'.format(ex,
																							exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/template/list', methods=['POST'])
def camsSettingsTemplateList():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode
		else:
			xmlFile = module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_DISCOVERY_NETWORK_LIST_CAMS_URL_PATH
			obj = convertXMLtoJSON(xmlFile)
			#print (obj)
			responseCode = rc_ok
			response = obj

		return jsonify(response), responseCode
	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo camsSettingsTemplateList: {} - line {}'.format(ex,
																						   exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/manual/list', methods=['POST'])
def camsSettingsManualList():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:
			xmlFile = module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_LIST_CAMS_MANUAL_FILE
			obj = convertXMLtoJSON(xmlFile)

			#response = module.queries.dbClasses().getcamsSettingsManualList()
			responseCode = rc_ok
		return jsonify(obj), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo camsSettingsManualList: {} - line {}'.format(ex,
																						 exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/manual/insert', methods=['POST'])
def camsSettingsManualInsert():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			xmlFile = module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_LIST_CAMS_MANUAL_FILE
			jsondata = request.json
			camera_id = jsondata['@id']
			vendor = jsondata['vendor']
			model = jsondata['model']
			ipAddress = jsondata['ipAddress']
			httpPort = jsondata['httpPort']
			macAddress = jsondata['macAddress']
			isOnvif = jsondata['isOnvif']
			inputConnectors = jsondata['inputConnectors']
			tree = ET.ElementTree(file=xmlFile)
			root = tree.getroot()
			findCamera = False

			for cam in root.findall('nevis-camera'):
				#print(camera_id);
				if str(camera_id) == cam.get('id'):
					findCamera = True
					#print('ManualInsert: ID CAMERA TROVATO')

					responseCode = rc_internal_server_error
					response = {"status": "KO", "msg": "La camera che stai inserendo e gia presente"}
					break

			if (findCamera is False):
				#print('ManualInsert: INSERIMENTO DI UNA NUOVA CAMERA')
				cam_root = ET.SubElement(root, "nevis-camera", id=str(camera_id))
				cam_root_model = ET.SubElement(cam_root, "model")
				cam_root_model.text = model
				cam_root_vendor = ET.SubElement(cam_root, "vendor")
				cam_root_vendor.text = vendor
				cam_root_ipAddress = ET.SubElement(cam_root, "ipAddress")
				cam_root_ipAddress.text = ipAddress
				cam_root_httpPort = ET.SubElement(cam_root, "httpPort")
				cam_root_httpPort.text = httpPort
				cam_root_macAddress = ET.SubElement(cam_root, "macAddress")
				cam_root_macAddress.text = macAddress
				cam_root_isOnvif = ET.SubElement(cam_root, "isOnvif")
				cam_root_isOnvif.text = isOnvif
				cam_root_inputConnectors = ET.SubElement(cam_root, "inputConnectors")
				cam_root_inputConnectors.text = inputConnectors
				# XML Indet
				indent(root)
				# Scrivo XML
				tree.write(xmlFile, encoding="UTF-8", xml_declaration=True)

				responseCode = rc_ok
				response = {"status": "OK", "msg": "La camera e stata aggiunta alla Lista."}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo camsSettingsManualInsert: {} - line {}'.format(ex,
																						   exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/manual/update', methods=['POST'])
def camsSettingsManualUpdate():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			xmlFile = module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_LIST_CAMS_MANUAL_FILE
			jsondata = request.json
			camera_id = jsondata['@id']
			vendor = jsondata['vendor']
			model = jsondata['model']
			ipAddress = jsondata['ipAddress']
			httpPort = jsondata['httpPort']
			macAddress = jsondata['macAddress']
			isOnvif = jsondata['isOnvif']
			inputConnectors = jsondata['inputConnectors']
			tree = ET.ElementTree(file=xmlFile)
			root = tree.getroot()
			findCamera = False

			for cam in root.findall('nevis-camera'):

				if str(camera_id) == cam.get('id'):
					findCamera = True
					cam.find('vendor').text = vendor
					cam.find('model').text = model
					cam.find('ipAddress').text = ipAddress
					cam.find('httpPort').text = httpPort
					cam.find('macAddress').text = macAddress
					cam.find('isOnvif').text = isOnvif
					cam.find('inputConnectors').text = inputConnectors
					#print('ManualUpdate: La camera e stata aggiornata')
					tree.write(xmlFile, encoding="UTF-8")
					responseCode = rc_ok
					response = {"status": "OK", "msg": "La configurazione della camera e stata aggiornata"}
					break

			if (findCamera is False):
				#print('ManualUpdate: La camera inserita non e presente nella lista.')
				responseCode = rc_internal_server_error
				response = {"status": "KO", "msg": "La camera inserita non e presente nella lista."}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo camsSettingsManualUpdate: {} - line {}'.format(ex,
																						   exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/manual/delete', methods=['POST'])
def camsSettingsManualDelete():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			xmlFile = module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_LIST_CAMS_MANUAL_FILE
			jsondata = request.json
			camera_id = jsondata['@id']
			tree = ET.ElementTree(file=xmlFile)
			root = tree.getroot()

			for cam in root.findall('nevis-camera'):

				if str(camera_id) == cam.get('id'):
					root.remove(cam)
					tree.write(xmlFile, encoding="UTF-8")

			responseCode = rc_ok
			response = {"status": "OK", "msg": "La camera e stata cancellata"}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo camsSettingsManualDelete: {} - line {}'.format(ex,
																						   exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/list', methods=['POST'])
def camsList():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			jsondata = request.json

			# checks - OLD     
			#if jsondata["sessionId"] != '' and not jsondata["sessionId"].isalnum():
			#	response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
			#	responseCode = rc_bad_request
			#	return jsonify(response), responseCode
			# end checks
			
			# check Session ID - Aggiunto nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
			if "sessionId" in jsondata and jsondata["sessionId"] != '':
				if not isSessionIdValid(jsondata["sessionId"]):
					response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
					responseCode = rc_bad_request
					return jsonify(response), responseCode
				else:
					sessionId = jsondata["sessionId"].split('~')[0]
			else:
				sessionId = generateRandom(10)	

			getCameraListRequestJson()
			responseCode = rc_ok
			#response = json.dumps(LocalData.cams)
			response = LocalData.cams.copy()
			response["status"] = "OK"

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO','msg': 'Errore metodo camsList: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/log/view', methods=['POST'])
def logView():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		elif 'process' not in request.json or 'data' not in request.json:

			response = {'status': 'KO', 'msg': 'Campi mancanti'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode
		
		#Rimosso nella 1.7.0
		#elif request.json["sessionId"] != '' and not isSessionIdValid(request.json["sessionId"]):
		#	response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
		#	responseCode = rc_bad_request
		#	return jsonify(response), responseCode

		else:

			jsondata = request.json

			# checks
			if jsondata["process"] == '' or jsondata["data"] == '':
				response = {'status': 'KO', 'msg': 'Verificare campi obbligatori'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			if jsondata["process"] == None or jsondata["data"] == None:
				response = {'status': 'KO', 'msg': 'Verificare campi obbligatori'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			# check Session ID - Aggiunto nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
			if "sessionId" in jsondata and jsondata["sessionId"] != '':
				if not isSessionIdValid(jsondata["sessionId"]):
					response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
					responseCode = rc_bad_request
					return jsonify(response), responseCode
				else:
					sessionId = jsondata["sessionId"].split('~')[0]
			else:
				sessionId = generateRandom(10)


			regCheck = '\d{4}-\d{2}-\d{2}'  # verify dates
			patternToTest = re.compile(regCheck)

			if not patternToTest.match(jsondata["data"]):
				response = {'status': 'KO', 'msg': 'Data non valida: AAAA-MM-GG'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
			# end checks

			process = jsondata["process"]
			dataLog = jsondata["data"]
			valori = dataLog.split('-')
			# print(valori[0] + valori[1] + valori[2])
			log_file_path = module.globalvars.LOG_FOLDER + '/LOG_' + process + '_' + valori[0] + valori[1] + valori[2] + '.csv'

			if not os.path.isfile(log_file_path):

				responseCode = 404
				response = {"status": "KO", "msg": "Non sono presenti LOG per la Data o per il Processo impostato."}

			else:

				logfile = open(log_file_path, 'r')
				reader = csv.DictReader(logfile)
				out =[row for row in reader]

				responseCode = rc_ok
				response = {"status": "OK", "log": out}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo logView: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/SnippetVideoList', methods=['POST'])
def snippetVideoList():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode
			
		

		else:

			#NON BISOGNEREBBE VALIDARE L'INPUT?
			
			jsondata = request.json
			
			# check Session ID - Aggiunto nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
			if "sessionId" in jsondata and jsondata["sessionId"] != '':
				if not isSessionIdValid(jsondata["sessionId"]):
					response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
					responseCode = rc_bad_request
					return jsonify(response), responseCode
				else:
					sessionId = jsondata["sessionId"].split('~')[0]
			else:
				sessionId = generateRandom(10)
			
			try:			
				if 'timezone' in request.json:
					tzinfo = pytz.timezone(jsondata["timezone"])
					print tzinfo
				else:
					tzinfo = None
			except Exception as ex:
				print ex
				tzinfo = None
			
			params = {}
			params["startDate"] = jsondata["startDate"]
			params["endDate"] =  jsondata["endDate"]
			params["quality"] = jsondata["quality"]
			#params["sessionId"] = jsondata["sessionId"] rimosso nella 1.7.0
			params["sessionId"] = sessionId # Aggiunto nella 1.7.0
			params["timezone"] = tzinfo
			recordingsList = module.recordingsList.recordingsList(params)

			if len(recordingsList.error) == 0:
				responseCode = rc_ok
				response = recordingsList.outputJson.copy()
				response["status"] = "OK"
			else:
				responseCode = rc_internal_server_error
				response = {"status": "KO", "msg": recordingsList.error}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo snippetVideoList: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/snippetVideo', methods=['POST'])
def mergeVideoStorico():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:
			
			jsondata = request.json

			# check mandatory fields
			if jsondata["encoder"] == '' or jsondata["quality"] == '' or \
				jsondata["idRequest"] == '' or jsondata["videoSourceId"] == '' or \
				jsondata["endDate"] == '' or jsondata["startDate"] == '':
				response = {'status': 'KO', 'msg': 'Verificare campi obbligatori'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			if jsondata["encoder"] == None or jsondata["quality"] == None or \
				jsondata["idRequest"] == None or jsondata["videoSourceId"] == None or \
				jsondata["endDate"] == None or jsondata["startDate"] == None:
				response = {'status': 'KO', 'msg': 'Verificare campi obbligatori'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			if jsondata["encoder"] not in ['native','preview']:
				response = {'status': 'KO', 'msg': 'Campo encoder: valore non valido'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			if jsondata["limits"] == '':
				jsondata["limits"] = 'False'
			elif jsondata["limits"] not in ['True','False']:
				response = {'status': 'KO', 'msg': 'Campo limits: valore non valido'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			if jsondata["quality"] not in ['HD','LD']:
				response = {'status': 'KO', 'msg': 'Campo quality: valore non valido'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			# check alphanum - modificato nella 1.7.0 il check sul session ID viene gestito sotto in maniera separata

			if not jsondata["idRequest"].isalnum():
				response = {'status': 'KO', 'msg': 'Il campo idRequest devoe essere alfanumerico'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
				
			# check Session ID - modificato nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
			if "sessionId" in jsondata and jsondata["sessionId"] != '':
				if not isSessionIdValid(jsondata["sessionId"]):
					response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
					responseCode = rc_bad_request
					return jsonify(response), responseCode
				else:
					sessionId = jsondata["sessionId"].split('~')[0]
			else:
				sessionId = generateRandom(10)
			

			params = {}
			params["videoSourceId"] = jsondata["videoSourceId"]

			slotInfo = getSlotInfoFromIdAndQuality(params["videoSourceId"], jsondata["quality"])

			if slotInfo["SlotFolder"] is not None:
			
				

				try:			
					if 'timezone' in request.json:
						tzinfo = pytz.timezone(jsondata["timezone"])
					else:
						tzinfo = None
				except Exception as ex:
					print ex
					tzinfo = None
			
				params["path"] = slotInfo["SlotFolder"]
				params["startDate"] = module.utcTranslator.translateToUTC( jsondata["startDate"], '%Y-%m-%d_%H-%M', tzinfo)
				params["endDate"] = module.utcTranslator.translateToUTC( jsondata["endDate"], '%Y-%m-%d_%H-%M', tzinfo)
				#params["sessionId"] = jsondata["sessionId"]# rimosso nella 1.7.0
				params["sessionId"] = sessionId # aggiunto nella 1.7.0
				params["encoder"] = jsondata["encoder"]
				params["quality"] = jsondata["quality"]
				params["limits"] = jsondata["limits"]
				params["callbackUrl"] = jsondata["callbackUrl"]
				params["idRequest"] = jsondata["idRequest"]

				if len(str(params["callbackUrl"])) == 0 or params["callbackUrl"] is None:

					# No Callback Mode (Sync)
					concat = module.concat.concatenate(params)

					if len(concat.error) == 0:

						concat.execute()

						if len(concat.error) == 0:

							responseCode = rc_ok
							#IP = get_lan_ip()
							# + ':' + module.globalvars.NEVIS_IS_PORT
							# MS - 20190430 - fix interfaccia bond
							# determine ip
							tmpJsonData = get_cams_conf()
							#print('DEBUG VARIABLES: tmpJsonData {}'.format(tmpJsonData))
							interfaceIp = request.host
							if 'SchedaReteNevis' in tmpJsonData and tmpJsonData['SchedaReteNevis'] is not None and tmpJsonData['SchedaReteNevis'] != '':
								tempInterfaceIp = get_interface_ip(tmpJsonData['SchedaReteNevis'])
								#print('DEBUG VARIABLES: tempInterfaceIp {}'.format(tempInterfaceIp))
								if tempInterfaceIp is not None:
									interfaceIp = tempInterfaceIp
							
							#print('DEBUG VARIABLES: interfaceIp {} - concat.outputFile {} - concat.pathFTP {} - concat.md5VideoFile {} - params["idRequest"] {}'.format(interfaceIp,concat.outputFile,concat.pathFTP,concat.md5VideoFile,params["idRequest"]))
							
							response = {"status":"OK",
										"httpUrl":"http://" + interfaceIp + "/history/" + concat.outputFile,
										"pathFTP" : concat.pathFTP,
										"md5": concat.md5VideoFile,
										"idRequest": params["idRequest"]}

						else:

							responseCode = rc_internal_server_error
							response = {"status": "KO", "msg": concat.error}

					else:

						responseCode = rc_internal_server_error
						response = {"status": "KO", "msg": concat.error}

				else:

					# Callback Mode (Async) - parametro requestHost aggiunto nella 1.5.1 (Fix necessaria per RuntimeError: Working outside of request context)
					thread.start_new_thread(snippetVideoAsync, (params, request.host))
					response = {"status": "OK", "msg": "Richiesta presa in carico.", "idRequest": params["idRequest"]}

			else:

				response = {'status': 'KO',
							'msg': 'Combinazione Camera/Qualita selezionata non presente su questo NVR'}
				responseCode = rc_bad_request

			#else:

				#responseCode = rc_internal_server_error
				#response = {"status": "KO", "msg": "Camera non trovata"}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo snippetVideo: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/settings/serverStatus', methods=['POST'])
def settingsServerStatus():
	try:
	
		# Aggiunto nella 1.7.0
		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode
			
		# check Session ID - modificato nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
		if "sessionId" in request.json and request.json["sessionId"] != '':
			if not isSessionIdValid(request.json["sessionId"]):
				response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
			else:
				sessionId = request.json["sessionId"].split('~')[0]
		else:
			sessionId = generateRandom(10)

		# Info CPU Percent Used
		cpuUsage = psutil.cpu_percent()

		# Info RAM Percent Used
		ram = psutil.phymem_usage()
		#ram_total = ram.total / 2 ** 20  # MiB.
		#ram_used = ram.used / 2 ** 20
		#ram_free = ram.free / 2 ** 20
		ramPercentUsed = ram.percent

		# Info Disk Percent Used
		disk = psutil.disk_usage('/nevis')
		#disk_total = disk.total / 2 ** 30  # GiB.
		#disk_used = disk.used / 2 ** 30
		#disk_free = disk.free / 2 ** 30
		diskPercentUsed = format(((float(disk.total - disk.free)/disk.total)*100), '.1f')
		try:
			# Info Slot
			slotPath = '/nevis/'
			excludes = ['public', 'lost+found', 'streaming', 'snapshot', 'history', 'upgrade', 'discarded']
			folders = {}
			#os.walk(slotPath, topdown=False):


			path = '/nevis'
			outputs = subprocess.check_output(
				['du', '-b', path, '--exclude=/nevis/lost+found', '--exclude=/nevis/public',
				 '--exclude=/nevis/discarded']).splitlines()
			for count, output in enumerate(outputs):
				output = output.strip()
				slotSize, slotFloder = output.split("\t")
				slotFloder = slotFloder.replace("/nevis/", "") #Aggiunto da Luca & Genna
				slot = slotFloder.split("_")
				if len(slot) == 4:
					id, slotType, slotName, quality = slot
					#folders[count] = {"slotId": slotName.replace("-", " "), "slotFloder": slotName, "slotSize": slotSize}
					#folders[count] = {"slotId": slotName, "slotFloder": slotName, "slotSize": slotSize} rimosso da LUCA & GENNA
					folders[count] = {"slotId": id, "slotFloder": slotFloder, "slotSize": slotSize, "videoSourceId": slotName} #aggiunto da LUCA & GENNA
			'''
			for root, dirs, files in os.walk(slotPath, topdown=False):
				dirs[:] = [d for d in dirs if d not in excludes]

				for dir in dirs:
					level = root.replace(dir, '').count(os.sep)
					#print level
					if level == 2:
						slotSize = getFolderSize('/nevis/'+dir)
						newDir = dir.split('_')
						folders[dir] = {"slotId": newDir[0], "slotFloder": dir, "slotSize": slotSize}
			'''

			response = {"cpuUsage": cpuUsage, "ramPercentUsed": ramPercentUsed, "diskPercentUsed": diskPercentUsed,
							"slotInfo": folders}
			responseCode = rc_ok  # default ok
			return json.dumps(response), responseCode

		except Exception as ex:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			response = {'status': 'KO',
						'msg': 'Errore serverStatus: {} - line {}'.format(ex, exc_tb.tb_lineno)}
			return json.dumps(response), rc_internal_server_error  # 500 = internal server error

	except Exception as ex:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO',
					'msg': 'Errore serverStatus: {} - line {}'.format(ex, exc_tb.tb_lineno)}
		return json.dumps(response), rc_internal_server_error  # 500 = internal server error

@app.route('/videoAvailability', methods=['POST'])
def videoAvailability():

	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))

		if not request.json or 'startDate' not in request.json or 'endDate' not in request.json or 'videoSourceId' not in request.json:

			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			jsondata = request.json

			if jsondata["startDate"] == '' or jsondata["endDate"] == '':
				response = {'status': 'KO', 'msg': 'Verificare campi obbligatori'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			if jsondata["startDate"] == None or jsondata["endDate"] == None:
				response = {'status': 'KO', 'msg': 'Verificare campi obbligatori'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
			
			try:			
				if 'timezone' in request.json:
					tzinfo = pytz.timezone(jsondata["timezone"])
				else:
					tzinfo = None
			except Exception as ex:
				print ex
				tzinfo = None
			

			params = {}
			params['videoSourceId'] = jsondata['videoSourceId']
			params['startDate'] = jsondata['startDate']
			params['endDate'] = jsondata['endDate']
			#params['startDate'] = module.utcTranslator.translateToUTC( jsondata['startDate'] + '-00', '%Y-%m-%d_%H-%M-%S', tzinfo)
			#params['endDate'] = module.utcTranslator.translateToUTC( jsondata['endDate'] + '-59', '%Y-%m-%d_%H-%M-%S', tzinfo)
			params['timezone'] = tzinfo
			
			videoAvailabilityObj = module.videoAvailability.videoAvailabilityClass(params)

			if len(videoAvailabilityObj.error) == 0:

				videoAvailabilityObj.execute()

				if len(videoAvailabilityObj.error) == 0:

					responseCode = rc_ok
					#IP = get_lan_ip()
					# + ':' + module.globalvars.NEVIS_IS_PORT

					#Senza unicode davanti va in errore
					json_obj = unicode(json.dumps(videoAvailabilityObj.outputDict, ensure_ascii=False))
					json_size = len(json_obj)

					#print 'JSON SIZE -----------------------------> ', json_size
					
					#with io.open('data-1h.txt', 'w', encoding='utf-8') as f:
					#	f.write(json_obj)

					if (int(json_size)< 2000000):
						response = {"status": "OK", "result": videoAvailabilityObj.outputDict}
					else:
						responseCode = rc_internal_server_error
						response = {"status": "KO", "msg": "Imposta un intervallo diverso."}

					#response = {"status": "OK", "result": "ok"}
					#print response

				else:

					responseCode = rc_internal_server_error
					response = {"status": "KO", "msg": videoAvailabilityObj.error}

			else:

				responseCode = rc_internal_server_error
				response = {"status": "KO", "msg": videoAvailabilityObj.error}

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo videoAvailability: {} - line {}'.format(ex,
																					exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/manual/begin/list', methods=['POST'])
def camsSettingsManualBeginList():
	try:
		response = None
		responseCode = rc_ok  # default ok
		#print('*** JSON Request: {}'.format(request.json))
		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode
		else:
			#check Session ID - aggiunto nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
			if "sessionId" in request.json and request.json["sessionId"] != '':
				if not isSessionIdValid(request.json["sessionId"]):
					response = {'status': 'KO', 'msg': 'Campo sessionId non disponibile con questo tipo di chiamata. Lasciare la variabile non valorizzata.'}
					responseCode = rc_bad_request
					return jsonify(response), responseCode
				else:
					sessionId = request.json["sessionId"].split('~')[0]
			else:
				sessionId = generateRandom(10)
				
			json_data = get_cams_conf()
			responseCode = rc_ok
		return jsonify(json_data), responseCode

	except Exception as ex:
		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo camsSettingsManualBeginList: {} - line {}'.format(ex,
																						 exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/cams/settings/manual/begin', methods=['POST'])
#@limiter.limit("1/minute")
def camsSettingsManualBegin():
	try:

		response = None
		responseCode = rc_ok  # default ok

		#print('*** JSON Request: {}'.format(request.json))
		print('*** TEST PT: {}'.format(request.json))

		if not request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'status': 'KO',
						'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:
			jsondata = request.json
			#Validazione dei campi "videoSourceId" - Aggiunta nella 1.5.1
			#Validazione dei campi "url", "quality" e "macAddress" - aggiunta nella versione 1.7.0
			#Validazione del campo "videoSourceId" - modificato nella 1.7.0
			cameras = jsondata['camera']
			inputValid = True
			banned_chars_list = [';', '_', '<', '>', '|', '&', '(',')', ' ', '`', '\"', '\'', '$', '\\', '\t', '\n', '\r' ]
			banned_chars_list_url = [';', '_', '<', '>', '|', '(',')', ' ', '`', '\"', '\'', '$', '\\', '\t', '\n', '\r' ]
			invalidVideoSourceIds = 0
			invalidQualities = 0
			invalidMacaddresses = 0
			invalidUrls = 0
			for cameraObj in cameras :
				videoSourceId = cameraObj['videoSourceId']
				videoSourceIdRes = any(x in videoSourceId for x in banned_chars_list)
				if bool(videoSourceIdRes) :
					invalidVideoSourceIds += 1
					inputValid = False
				
				quality = cameraObj['quality']
				if not (quality.upper() == 'HD' or quality.upper() == 'LD'):
					invalidQualities += 1
					inputValid = False
				
				macaddress = cameraObj['macAddress']
				macaddressRes = any(y in macaddress for y in banned_chars_list)
				if macaddressRes :
					invalidMacaddresses += 1
					inputValid = False
					
				url = cameraObj['url']
				urlRes = any(z in url for z in banned_chars_list_url)
				if urlRes:
					invalidUrls += 1
					inputValid = False
					
			if not inputValid:
				responseCode = rc_validation_error
				msg = ""
				if invalidVideoSourceIds > 0 :
					msg += "Sono presenti " + str(invalidVideoSourceIds) + " registrazioni con campo videoSourceId non valido.\n"
				if invalidQualities > 0 :
					msg += "Sono presenti " + str(invalidQualities) + " registrazioni con campo quality non valido. Il campo quality deve assumere i valori HD o LD.\n"
				if invalidMacaddresses > 0 :
					msg += "Sono presenti " + str(invalidMacaddresses) + " registrazioni con campo macaddress non valido.\n"
				if invalidUrls > 0 :
					msg += "Sono presenti " + str(invalidUrls) + " registrazioni con campo url non sicuro.\n"
				response = {"status": "KO", "msg": msg}
			else:
				with io.open(module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_CAMS_CONF, 'w', encoding='utf8') as outfile:
					str_ = json.dumps(jsondata, indent=4, sort_keys=True, separators=(',', ': '), ensure_ascii=False)
					outfile.write(to_unicode(str_))
				
				responseCode = rc_ok
				response = {"status":"OK", "msg":"Configurazione salvata correttamente."}
		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo camsSettingsManualBegin: {} - line {}'.format(ex,
																						 exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/fotografiaSistema', methods=['GET'])
def fotografiaSistema():
	responseCode = rc_ok  # default ok
	try:
		getCameraListRequestJson()
		response = module.fotografiaSistemaModule.calcFotografia()
		response["status"] = "OK"
		#print('*** Fotografia Sistema: {}'.format(response))
		return jsonify(response), responseCode
	except Exception as ex:
		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO', 'msg': 'Exception Fotografia del Sistema: {} - line {}'.format(ex, exc_tb.tb_lineno)}
		#print('*** Exception Uptime Server keepAlive: {} - {}'.format(ex, exc_tb.tb_lineno))
		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/snapshot', methods=['POST'])
def snapshot():
	try:

		response = None
		responseCode = rc_ok  # default ok

		# print('*** JSON Request: {}'.format(request.json))

		if not request.json:

			response = {'status': 'KO', 'msg': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		else:

			jsondata = request.json

			if jsondata["videoSourceId"] == '' or jsondata["videoSourceId"] == None:
				response = {'status': 'KO', 'msg': 'Verificare campi obbligatori'}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			params = {}
			params["videoSourceId"] = jsondata["videoSourceId"]

			responseModule = module.snapshotModule.getSnapshot(params["videoSourceId"])

			if responseModule['status'] == 'ok':

				responseCode = rc_ok
				response = {"status": "OK", "videoSourceId": params["videoSourceId"], "pathFTP": responseModule["pathFTP"]}

			else:

				responseCode = rc_internal_server_error
				response = {"status": "KO", "msg": responseModule['msg']}

		return jsonify(response), responseCode
	except Exception as ex:

		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		#print("Unhandled error snapshot\n{}".format(ex))
		response = {'status': 'KO', 'msg': 'Errore metodo snapshot: {} - line {}'.format(ex, exc_tb.tb_lineno)}
		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/startRecordings', methods=['GET'])
#@limiter.limit("1/minute")
@host_limit
def startRecordings():
	try:
		response = None
		responseCode = rc_ok  # default ok
		url = 'http://localhost:8888/startRecordings'
		r = requests.get(url)
		response = json.loads(r.text)
		if r.status_code != 200:
			responseCode = rc_bad_request
		return jsonify(response), responseCode
	except Exception as ex:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO', 'msg': 'Errore startRecordings: {} - line {}'.format(ex, exc_tb.tb_lineno)}
		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/stopRecordings', methods=['GET'])
@host_limit
def stopRecordings():
	try:
		response = None
		responseCode = rc_ok  # default ok
		url = 'http://localhost:8888/stopRecordings'
		r = requests.get(url)
		response = json.loads(r.text)
		if r.status_code != 200:
			responseCode = rc_bad_request
		return jsonify(response), responseCode
	except Exception as ex:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		response = {'status': 'KO', 'msg': 'Errore stopRecordings: {} - line {}'.format(ex, exc_tb.tb_lineno)}
		return jsonify(response), rc_internal_server_error  # 500 = internal server error

#Database
@jwt.unauthorized_loader
def my_unauthorized_callback(err):
	return jsonify({
		'status': 'KO',
		'msg': 'Autorizzazione non presente nell\'header.'
	}), 401

@jwt.expired_token_loader
def my_expired_token_callback():
	return jsonify({
		'status': 'KO',
		'msg': 'Token scaduto. Effettua la richiesta di un nuovo token.'
	}), 401

@jwt.invalid_token_loader
def my_invalid_token_callback(err):
	return jsonify({
		'status': 'KO',
		'msg': 'Token non valido. Effettua la richiesta di un nuovo token.'
	}), 422

@app.route('/token/auth', methods=['POST'])
def token():
	email = request.json.get('email', None)
	password = request.json.get('password', None)
	
	config = SafeConfigParser()
	config.read(module.globalvars.NEVIS_CONFIG_INI) 
	max_attempts = config.get('SETTINGS','MAX_LOGIN_ATTEMPTS')
	
	if not max_attempts is None and max_attempts != '' and max_attempts.isdigit():
		max_login_attempts = int(max_attempts)
		if max_login_attempts > 10:
			max_login_attempts = 10
	else:
		max_login_attempts = 10
	
	#print("max_login_attempts: " + str(max_login_attempts))
	user = module.database.getUser(email)
	print('User ' + user.email)
	
	if user is None:
		return jsonify({'status': 'KO', "msg": "Accesso negato. Username o password errati."}), 401
	
	if not user.active :
		response = {'status': 'KO', "msg": "Accesso negato. Utenza disabilitata."}
		return jsonify(response), 401
	
	ret = module.database.loginCheck(email, password)
	if ret is True:
		params = {}
		params['user_id'] = user.user_id
		params['attempts'] = 0
		module.database.updateUsersAttempts(params)
		response = {'status': 'OK', 'access_token': create_access_token(identity=email)}
		return jsonify(response), rc_ok
	else:
		user_attempts = module.database.getUserAttempts(user.user_id)
		if user_attempts is None:
			print('Add attempts...')
			module.database.putUserAttempts(user.user_id, 1, time.mktime(datetime.now().timetuple()))
		else :
			#print('Actual Attempts ' + str(user_attempts.attempts))
			new_attempts = user_attempts.attempts + 1
			
			params = {}
			params['user_id'] = user.user_id
			params['attempts'] = new_attempts
			module.database.updateUsersAttempts(params)
			print('Tentativi: ' + str(new_attempts))
						
			if new_attempts >= max_login_attempts:
				print('Disabilito utenza ' + user.email)
				userparams = {}
				userparams['email'] = user.email
				userparams['name'] = user.name
				userparams['last_name'] = user.last_name
				#userparams['password'] = user.password
				userparams['active'] = '0'
				
				ret = module.database.updateUsers(userparams)
				print (ret)
		    
		return jsonify({'status': 'KO', "msg": "Accesso negato. Username o password errati."}), 401

@app.route('/users/list', methods=['GET'])
@jwt_required
def listUsers():
	try:
		responseCode = rc_ok
		response = module.database.getUsers()
		return jsonify(response), responseCode
	except Exception as ex:
		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo listUsers: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/users/add', methods=['POST'])
@jwt_required
def addUser():
	try:
		response = None
		responseCode = rc_ok

		if not request.json:
			response = {'status': 'KO', 'msg': 'Invalid Json Request'}
			return jsonify(response), rc_bad_request
		else:
			jsondata = request.json

			#Verifico che i tutte le key dei campi siano presneti nel jsondata
			if  jsondata.get('active') is None or  jsondata.get('email') is None or \
				jsondata.get('name') is None or  jsondata.get('last_name') is None or \
				jsondata.get('password') is None or  jsondata.get('role') is None:
				response = {
					'status': 'KO',
					'msg': 'Tutti i campi sono obbligatori'
				}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			#Verifico che tutti i campi non siano vuoti
			if  jsondata['active'] is None or jsondata['active'] == '' or \
				jsondata["email"] is None or jsondata["email"] == '' or \
				jsondata["name"] is None or jsondata["name"] == '' or \
				jsondata["last_name"] is None or jsondata["last_name"] == '' or \
				jsondata["password"] is None or jsondata["password"] == '' or \
				jsondata["role"] is None or jsondata["role"] == '':
				response = {
					'status': 'KO',
					'msg': 'Tutti i campi sono obbligatori'
				}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
				
			#Aggiunto nella 1.7.0 - Fix per vulnerability Weak password policy
			if not isPasswordValid(jsondata["password"]):
				response = {
					'status': 'KO',
					'msg': 'Password debole. Dovrebbe essere formata da almeno 8 caratteri e \
					contenere almeno una lettera minuscola, una lettera maiuscola, un numero ed \
					un carattere speciale (es: ! # @ etc.) '
				}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
				

			params = {}
			params["active"] = jsondata["active"]
			params["email"] = jsondata["email"]
			params["name"] = jsondata["name"]
			params["last_name"] = jsondata["last_name"]
			params["password"] = jsondata["password"]
			params["role"] = jsondata["role"]

			response = module.database.putUsers(params["active"], params["email"], params["name"], params["last_name"], params["password"], params["role"])
		return jsonify(response), responseCode
	except Exception as ex:
		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo addwUser: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/users/edit', methods=['POST'])
@jwt_required
def editUser():
	try:
		response = None
		responseCode = rc_ok

		if not request.json:
			response = {'status': 'KO', 'msg': 'Invalid Json Request'}
			return jsonify(response), rc_bad_request
		else:
			jsondata = request.json
			#OLD Verifico che i tutte le key dei campi siano presneti nel jsondata
			#if jsondata.get('email') is None:
			#	response = {
			#		'status': 'KO',
			#		'msg': 'Il campo email e\' obbligatorio.'
			#	}
			#	responseCode = rc_bad_request
			#	return jsonify(response), responseCode

			#Verifico che i tutte le key dei campi siano presneti nel jsondata
			if  jsondata.get('active') is None or  jsondata.get('email') is None or \
				jsondata.get('name') is None or  jsondata.get('last_name') is None or \
				jsondata.get('password') is None or  jsondata.get('role') is None:
				response = {
					'status': 'KO',
					'msg': 'Tutti i campi sono obbligatori'
				}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			#Verifico che tutti i campi non siano vuoti
			if  jsondata['active'] is None or jsondata['active'] == '' or \
				jsondata["email"] is None or jsondata["email"] == '' or \
				jsondata["name"] is None or jsondata["name"] == '' or \
				jsondata["last_name"] is None or jsondata["last_name"] == '' or \
				jsondata["password"] is None or jsondata["password"] == '' or \
				jsondata["role"] is None or jsondata["role"] == '':
				response = {
					'status': 'KO',
					'msg': 'Tutti i campi sono obbligatori'
				}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
				
			#Aggiunto nella 1.7.0 - Fix per vulnerability Weak password policy
			if not isPasswordValid(jsondata["password"]):
				response = {
					'status': 'KO',
					'msg': 'Password debole. Dovrebbe essere formata da almeno 8 caratteri e \
					contenere almeno una lettera minuscola, una lettera maiuscola, un numero ed \
					un carattere speciale tra [! ? @ _ - .] '
				}
				responseCode = rc_bad_request
				return jsonify(response), responseCode

			response = module.database.updateUsers(jsondata)
		return jsonify(response), responseCode
	except Exception as ex:
		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo updateUser: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error

@app.route('/users/delete', methods=['POST'])
@jwt_required
def delUser():
	try:
		response = None
		responseCode = rc_ok

		if not request.json:
			response = {'status': 'KO', 'msg': 'Invalid Json Request'}
			return jsonify(response), rc_bad_request
		else:
			jsondata = request.json
			if jsondata.get('email') is None:
				response = {
					'status': 'KO',
					'msg': 'Il campo email e\' obbligatorio.'
				}
				responseCode = rc_bad_request
				return jsonify(response), responseCode
			response = module.database.deleteUsers(jsondata)
		return jsonify(response), responseCode
	except Exception as ex:
		# handle unexpected script errors
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print("Unhandled error\n{}".format(ex))

		response = {'status': 'KO',
					'msg': 'Errore metodo updateUser: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error




# LUKS ############ POST/GET SECTION ################################

'''START LUKS COMMENT
@app.route('/luksRestService/slotList', methods=['GET'])
def get_slotList():

	slotList = checkLuksSlots()

	# return
	return jsonify({'slotList': slotList})


@app.route('/luksRestService/addPassphrase', methods=['POST'])      # example json {"Existing Passphrase": "passphrase1", "New Passphrase": "newPassphrase", "Target Slot Number": "7"}
def insert_passp():

	try:

		luksDumpLines = None
		response = None
		responseCode = rc_ok # default ok

		print('*** JSON Request: {}'.format(request.json))

		if (not request.json) or 'Existing Passphrase' not in request.json or 'New Passphrase' not in request.json or 'Target Slot Number' not in request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'Esito': 'KO',
						'Descrizione': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		if request.json['Target Slot Number'] not in ['0', '1', 0, 1]: # slots 0 and 1 are off limits

			if int(request.json['Target Slot Number']) >= 2 and int(request.json['Target Slot Number']) <= 7:  # slots 0 and 1 are off limits

				# security check, look for special chars
				if securityChecks(request.json['New Passphrase']) and securityChecks(request.json['Existing Passphrase']):

					slotList = checkLuksSlots()

					if slotList is not None and len(slotList) != 0:

						# look for empty slots
						for element in slotList:

							if element['Slot Number'] == request.json['Target Slot Number']:

								if element['Slot Status'] == 'DISABLED': # empty slot

									luksDumpLines = insertPassp(request.json)

									# check for errors
									if luksDumpLines is None or len(luksDumpLines) != 0:  # if len(luksDumpLines) != 0 there is an error

										response = {'Esito': 'KO',
													'Descrizione': 'Errore: {}'.format(luksDumpLines[0])}
										responseCode = rc_bad_request

									else:

										response = {'Esito': 'OK',
													'Descrizione': 'Nuova passphrase aggiunta correttamente'}
										responseCode = rc_ok

								else:

									response = {'Esito': 'KO',
												'Descrizione': 'Slot number occupato'}
									responseCode = rc_bad_request

					else:

						response = {'Esito': 'KO',
									'Descrizione': 'Slot list non trovata'}
						responseCode = rc_bad_request

				else: # security check failed

					response = {'Esito': 'KO',
								'Descrizione': 'Nella passphrase in input sono ammessi solo caratteri alfanumerici'}
					responseCode = rc_bad_request

			else: # slot number > 7

				response = {'Esito': 'KO',
							'Descrizione': 'Slot number deve essere compreso fra 2 e 7'}
				responseCode = rc_bad_request

		else:
			response = {'Esito': 'KO',
						'Descrizione': 'Gli slot 0 ed 1 sono riservati'}
			responseCode = rc_bad_request

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		print("Unhandled error\n{}".format(ex))

		response = {'Esito': 'KO',
					'Descrizione': 'Errore metodo addPassphrase: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error


@app.route('/luksRestService/deletePassphrase', methods=['POST'])      # example json {"Existing Passphrase": "passphrase1", "Target Slot Number": "7"}
def delete_passp():

	try:
		luksDumpLines = None
		response = None
		responseCode = rc_ok # default ok

		print('*** JSON Request: {}'.format(request.json))

		if (not request.json) or 'Existing Passphrase' not in request.json or 'Target Slot Number' not in request.json:
			# abort(rc_bad_request, 'Invalid Json Request')
			response = {'Esito': 'KO',
						'Descrizione': 'Invalid Json Request'}
			responseCode = rc_bad_request
			return jsonify(response), responseCode

		if request.json['Target Slot Number'] not in ['0', '1', 0, 1]: # slots 0 and 1 are off limits

			if int(request.json['Target Slot Number']) >= 2 and int(request.json['Target Slot Number']) <= 7:  # slots 0 and 1 are off limits

				# security check, look for special chars
				if securityChecks(request.json['Existing Passphrase']):

					slotList = checkLuksSlots()

					if slotList is not None and len(slotList) != 0:

						# look for empty slots
						for element in slotList:

							if element['Slot Number'] == request.json['Target Slot Number']:

								if element['Slot Status'] == 'ENABLED': # slot with passphrase

									luksDumpLines = deletePassp(request.json)

									# check for errors
									if luksDumpLines is None or len(luksDumpLines) != 0:  # if len(luksDumpLines) != 0 there is an error

										response = {'Esito': 'KO',
													'Descrizione': 'Errore: {}'.format(luksDumpLines[0])}
										responseCode = rc_bad_request

									else:

										response = {'Esito': 'OK',
													'Descrizione': 'Passphrase rimossa correttamente'}
										responseCode = rc_ok

								else:
									response = {'Esito': 'KO',
												'Descrizione': 'Slot number vuoto'}
									responseCode = rc_bad_request

					else:

						response = {'Esito': 'KO',
									'Descrizione': 'Slot list non trovata'}
						responseCode = rc_bad_request

				else: # security check failed

					response = {'Esito': 'KO',
								'Descrizione': 'Nella passphrase in input sono ammessi solo caratteri alfanumerici'}
					responseCode = rc_bad_request

			else:  # slot number > 7

				response = {'Esito': 'KO',
							'Descrizione': 'Slot number deve essere compreso fra 2 e 7'}
				responseCode = rc_bad_request

		else:

			response = {'Esito': 'KO',
						'Descrizione': 'Gli slot 0 ed 1 sono riservati'}
			responseCode = rc_bad_request

		return jsonify(response), responseCode

	except Exception as ex:

		# handle unexpected script errors
		print("Unhandled error\n{}".format(ex))

		response = {'Esito': 'KO',
					'Descrizione': 'Errore metodo deletePassphrase: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error       # 500 = internal server error

END LUKS COMMENT'''

# UPTIME SERVER

'''
@app.route('/uptimeServer/lastPowerOffAndStartUp', methods=['GET'])    # {"@id" : "001", "Status" : "Running"}
def lastPowerOffAndStartUp():
	try:

		response = None
		responseCode = rc_ok  # default ok

		lastStartUp, lastPowerOff = module.uptimeServerModule.writeUptimeServer.calcLastPowerOffAndStartUp()

		response = {'Last Start Up': lastStartUp, 'Last Power Off': lastPowerOff}

		return jsonify(response)

	except Exception as ex:

		# handle unexpected script errors
		response = {'status': 'KO',
					'msg': 'Exception Uptime Server metodo lastPowerOffAndStartUp: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error


@app.route('/uptimeServer/completeTimeline', methods=['GET'])
def completeList():

	try:

		response = None
		responseCode = rc_ok  # default ok

		# extract first column, readable
		listToReturn = [row[0] for row in module.uptimeServerModule.writeUptimeServer.buffer]

		# return
		return jsonify(listToReturn)

	except Exception as ex:

		response = {'status': 'KO',
					'msg': 'Errore Uptime Server metodo completeTimeline: {} - line {}'.format(ex, exc_tb.tb_lineno)}

		return jsonify(response), rc_internal_server_error  # 500 = internal server error
'''


# Support FUNCTIONS #####################################################
def get_mount(name):
	#p = subprocess.Popen('df -h --output=target | grep "%s"' % name, stdout=subprocess.PIPE, shell=True)
	#output, _ = p.communicate()
	dir_pub       = "/nevis/public"
	dir_streaming = dir_pub + "/streaming"
	dir_history   = dir_pub + "/history"
	dir_snapshot  = dir_pub + "/snapshot"

	check = 1
	check_mount = os.system('df -h --output=target|grep '+name)
	#print 'check_mount', check_mount
	if check_mount == 0:
		if not os.path.exists(dir_pub):
			#print '###############inizio la creazione 1############'
			os.makedirs(dir_pub)
		if not os.path.exists(dir_streaming):
			#print '###############inizio la creazione 2############'
			os.makedirs(dir_streaming)
		if not os.path.exists(dir_history):
			#print '###############inizio la creazione 3############'
			os.makedirs(dir_history)
		if not os.path.exists(dir_snapshot):
			#print '###############inizio la creazione 4############'
			os.makedirs(dir_snapshot)
		check = 0
	return check

def get_cams_conf():
	json_data = ''
	json_cams_conf_file = module.globalvars.NEVIS_CONFIG_FOLDER + '/' + module.globalvars.NEVIS_CAMS_CONF

	with open(json_cams_conf_file) as json_file:
		json_data = json.load(json_file)

	return json_data


def get_process_id(name):
	"""Return process ids found by (partial) name or regex.
	#finder = 'ps aux |grep -ve "grep" |grep -E "/streaming/" |awk "{print $2}"'
	"""
	child = subprocess.Popen(['pgrep', '-U', apacheUser, '-f', name], stdout=subprocess.PIPE, shell=False)
	response = child.communicate()[0]
	return [int(pid) for pid in response.split()]

'''
def dict_to_xml(tag, d):
	
	# Turn a simple dict of key/value pairs into XML
	
	elem = Element(tag)
	for key, val in d.items():
		child = Element(key)
		child.text = str(val)
		elem.append(child)
	return elem
'''
#
def getCameraListRequestJson():
	headers = {'Content-type': 'application/json', 'Accept': 'text/plain'}
	data = {'test': 'test'}
	res = requests.get('http://localhost:8080/recList/completeList')
	json_obj = json.loads(res.text)
	LocalData.cams = {}

	for cam in json_obj['Cams']['Cam']:
		id = cam['@id']
		ip = cam['Ip']
		mac = cam['Mac']
		vendor = cam['Vendor']
		model = cam['Model']
		videoSourceId = cam['VideoSourceId']
		description = cam['Description']
		#sensorId = cam['SensorId']
		encoder = cam['Encoder']
		quality = cam['Quality']
		slotFolder = cam['SlotFolder']
		depthRec = cam['DepthRec']
		url = cam['Url']
		urlLive = cam['UrlLive']
		pid = cam['Pid']
		status = cam['Status']
		#data = {"ip": ip, "mac": mac, "vendor": vendor, "model": model, "videoSourceId": videoSourceId, #sensorId": sensorId, "profile": profile, "slotFolder": slotFolder, "url": url, "pid": pid, "status": status}
		data = {"ipAddress": ip, "depthRec": depthRec, "macAddress": mac, "vendor": vendor, "model": model, "videoSourceId": videoSourceId, "description": description,
				"encoder": encoder, "quality": quality, "slotFolder": slotFolder, "url": url, "urlLive": urlLive, "pid": pid, "statusRecording": status}

		LocalData.cams[id] = data

def getCameraList():
	xmlFile = module.globalvars.NEVIS_SERVICE_FOLDER + "/rec_list.xml"
	LocalData.cams = {}
	if os.path.isfile(xmlFile):
		tree = ET.ElementTree(file=xmlFile)
		root = tree.getroot()
		for cam in root.findall('Cam'):
			id = cam.get('id')
			ip = cam.find('Ip').text
			mac = cam.find('Mac').text
			vendor = cam.find('Vendor').text
			model = cam.find('Model').text
			videoSourceId = cam.find('VideoSourceId').text
			profile = cam.find('Profile').text
			url = cam.find('Url').text
			pid = cam.find('Pid').text
			status = cam.find('Status').text
			data = {"ip": ip, "mac": mac, "vendor": vendor, "model": model, "videoSourceId": videoSourceId, "profile": profile, "url": url, "pid": pid,
					"status": status}
			LocalData.cams[id] = data

def getFolderSize(p):
	from functools import partial
	prepend = partial(os.path.join, p)
	return sum([(os.path.getsize(f) if os.path.isfile(f) else getFolderSize(f)) for f in map(prepend, os.listdir(p))])

def generateRandom(length):
	"""Return a random string of specified length (used for session id's)"""
	return ''.join([random.choice(chars) for i in range(length)])

# Aggiunto nella v.1.7.0 - vulnerability "Broken access control:missing session validation"
def isSessionIdValid(sessionId):
	if '~' in sessionId :
		session, digest = sessionId.split('~');
		index = int(digest[0:2])
		hash = digest[2:6]
		m = hashlib.md5()
		m.update(session)
		calc_digest = m.hexdigest()
		calc_hash = calc_digest[index:index+4]
		return hash == calc_hash
	else:
		return False
		
# Aggiunto nella v.1.7.0 - vulnerability "Weak password policy"
def isPasswordValid(password):
	lengthCheck = len(password) > 8
	digitCheck = False
	uppercaseCheck = False
	lowercaseCheck = False
	specialcharcheck = False
	
	for char in password:
		if char.isdigit():
			digitCheck = True
		if char.isupper():
			uppercaseCheck = True
		if char.islower():
			lowercaseCheck = True
		#if char in ['!','?','@','_','-','.']:
		if char in string.punctuation:
			specialcharcheck = True
			
	return lengthCheck and digitCheck and uppercaseCheck and lowercaseCheck and specialcharcheck
	
	
	

def convertXMLtoJSON(xml_file, xml_attribs=True):
	with open(xml_file, "rb") as f:  # notice the "rb" mode
		d = xmltodict.parse(f, xml_attribs=xml_attribs)
		return json.dumps(d, indent=4)

'''
def checkLuksSlots():
	slotList = []

	# prepare command execution
	commandArgs = ['cryptsetup', 'luksDump', '/dev/sda3']

	result = subprocess.Popen(commandArgs, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	luksDumpLines = [x[:-1] for x in result.stdout.readlines() if ("Key Slot" in x)]

	#print('*** luksDumpLines Lines: {}'.format(luksDumpLines))

	# put into dictionary
	for element in luksDumpLines:
		slot = element.split(':')[0][-1]
		slotStatus = element.split(':')[1][1:]

		tempDict = {'Slot Number': slot, 'Slot Status': slotStatus}

		slotList.append(tempDict)

	#print('*** slotList: {}'.format(slotList))

	return slotList
	
def insertPassp(requestJson):
	err = []

	echoCommand = ['echo', '-e', requestJson['Existing Passphrase'] + '\\n' + requestJson['New Passphrase']]
	cryptCommand = ['cryptsetup', 'luksAddKey', '/dev/sda3', '-S', requestJson['Target Slot Number']]

	proc1 = subprocess.Popen(echoCommand, shell=False, stdout=subprocess.PIPE)
	proc2 = subprocess.Popen(cryptCommand, shell=False, stdin=proc1.stdout, stdout=subprocess.PIPE,
							 stderr=subprocess.PIPE)

	proc1.stdout.close()  # Allow proc1 to receive a SIGPIPE if proc2 exits.
	out, err = proc2.communicate()

	#print('*** out, err (insertPassp): {} - {}'.format(out, err))

	return err

def deletePassp(requestJson):
	echoCommand = ['echo', '-n', requestJson['Existing Passphrase']]
	cryptCommand = ['cryptsetup', 'luksRemoveKey', '/dev/sda3', '-S', requestJson['Target Slot Number']]

	proc1 = subprocess.Popen(echoCommand, shell=False, stdout=subprocess.PIPE)
	proc2 = subprocess.Popen(cryptCommand, shell=False, stdin=proc1.stdout, stdout=subprocess.PIPE,
							 stderr=subprocess.PIPE)

	proc1.stdout.close()  # Allow proc1 to receive a SIGPIPE if proc2 exits.
	out, err = proc2.communicate()

	#print('*** out, err (insertPassp): {} - {}'.format(out, err))

	return err

def securityChecks(requestPassphrase):
	checkVar = True

	if requestPassphrase.isalnum():
		checkVar = True  # no special chars
	else:
		checkVar = False  # special chars

	return checkVar

'''
#XML
def indent(elem, level=0):
	i = "\n" + level*"  "
	if len(elem):
		if not elem.text or not elem.text.strip():
			elem.text = i + "  "
		if not elem.tail or not elem.tail.strip():
			elem.tail = i
		for elem in elem:
			indent(elem, level+1)
		if not elem.tail or not elem.tail.strip():
			elem.tail = i
	else:
		if level and (not elem.tail or not elem.tail.strip()):
			elem.tail = i


def streamingLiveCleaner():
	# Processes Kill
	streamingLiveActiveDel = get_process_id("hls")
	for sLA in streamingLiveActiveDel:
		os.kill(sLA, 9)
		#print ("Process Streaming Live with PID:" + str(sLA) + " killed!")

	# Cleaner Folders
	streamingLiveFoldersPath = '/nevis/public/streaming/'
	for root, dirs, files in os.walk(streamingLiveFoldersPath, topdown=True):
		for dir in dirs:
			directory = streamingLiveFoldersPath + dir
			shutil.rmtree(directory)
			#print ("Folder:" + directory + " deleted!")
		break


def getSlotInfoFromId(videoSourceId):

	# get rec list url
	confFile = module.globalvars.NEVIS_CONFIG_XML  # '/nevisApp/conf/config.xml'
	recListUrl = None

	# open empty video file path
	tree = ET.parse(confFile)
	root = tree.getroot()

	for child in root:
		if child.get('key') == 'ws.endpoint.local.recordings':
			recListUrl = child.text

	# search for cam info
	slotInfo = {}
	resp = requests.get(recListUrl)
	resp = json.loads(resp.text)

	# select correct camera
	for element in resp['Cams']['Cam']:

		if element['VideoSourceId'] == videoSourceId:

			slotInfo['SlotFolder'] = element['SlotFolder']
			slotInfo['Id'] = element['@id']

	return slotInfo


def getSlotInfoFromIdAndQuality(videoSourceId, quality):

	# get rec list url
	confFile = module.globalvars.NEVIS_CONFIG_XML  # '/nevisApp/conf/config.xml'
	recListUrl = None
	recordingsPath = None

	# open empty video file path
	tree = ET.parse(confFile)
	root = tree.getroot()

	for child in root:
		if child.get('key') == 'ws.endpoint.local.recordings':
			recListUrl = child.text

		if child.get('key') == 'path.registrazioni':
			recordingsPath = child.text

	# search for cam info
	slotInfo = {'Id': None, 'SlotFolder': None}
	resp = requests.get(recListUrl)
	resp = json.loads(resp.text)

	# select correct camera
	if resp is not None and resp['Cams'] is not None and len(resp['Cams']['Cam']) > 0:

		for element in resp['Cams']['Cam']:

			if element['VideoSourceId'] == videoSourceId and element['Quality'] == quality:

				slotInfo['SlotFolder'] = element['SlotFolder']
				slotInfo['Id'] = element['@id']
				break

	# look for slot folder in historical data
	if slotInfo['SlotFolder'] is None:

		for root, dirs, files in os.walk(recordingsPath):

			for singleDir in dirs:

				if '_' in singleDir:

					singleDirvideoSourceId = singleDir.split('_')[2]
					singleDirQuality = singleDir.split('_')[3]

					if videoSourceId == singleDirvideoSourceId and quality == singleDirQuality: # found

						slotInfo['SlotFolder'] = singleDir
						break

			break

	return slotInfo

# Paremetro "requestHost" aggiunto nella 1.5.1 
#(Fix necessaria per RuntimeError: Working outside of request context
def snippetVideoAsync(params, requestHost):

	#Verificare che non ci sia bisogno di tradurre le date in UTC anche qui.
	#N.B. la traduzione la effettua snippetVideo che in casi particolari invoca
	#questo metodo
	concat = module.concat.concatenate(params)

	if len(concat.error) == 0:

		concat.execute()

		if len(concat.error) == 0:

			#tempVar = concat

			responseCode = rc_ok
			#IP = get_lan_ip()
			# + ':' + module.globalvars.NEVIS_IS_PORT
			# MS - 20190430 - fix interfaccia bond
			# determine ip
			tmpJsonData = get_cams_conf()
			# Modificato nella 1.5.1 
			# Fix necessaria per RuntimeError: Working outside of request context
			interfaceIp = requestHost
			if 'SchedaReteNevis' in tmpJsonData and tmpJsonData['SchedaReteNevis'] is not None and tmpJsonData['SchedaReteNevis'] != '':
				tempInterfaceIp = get_interface_ip(tmpJsonData['SchedaReteNevis'])
				if tempInterfaceIp is not None:
					interfaceIp = tempInterfaceIp			

			response = {"status": 0,
						"httpUrl": "http://" + interfaceIp + "/history/" + concat.outputFile,
						"filename": concat.pathFTP,
						"md5": concat.md5VideoFile,
						"idRequest": params["idRequest"]
						}

		else:

			responseCode = rc_internal_server_error
			response = {"status": 1, "msg": concat.error, "idRequest": params["idRequest"]}

	else:

		responseCode = rc_internal_server_error
		response = {"status": 1, "msg": concat.error, "idRequest": params["idRequest"]}

	# Vecchio codice - attaccabile con una ZIP BOMB
	# Rimosso nella versione 1.7.0 per fix vulnerability "Denial of Service - exhausting system resources"
	# send  response
	# respCallback = requests.post(params['callbackUrl'], json=response)
	# resp = json.loads(respCallback.text)
	
	# Aggiunto nella versione 1.7.0 per fix vulnerability "Denial of Service - exhausting system resources"
	# send async response
	try:
		r = requests.post(params['callbackUrl'], json=response, allow_redirects=False, stream=True)
		print(r.headers)
		r.close()
	except Exception as ex:
		print("Unhandled error\n{}".format(ex))
		print("Closing async response connection anyway")
		r.close()

# MAIN ##############################################################
@app.before_first_request
def startNevisIs():
	#formatter = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
	#handler = logging.handlers.TimedRotatingFileHandler("/nevis_app/nevis_latest/log/nevis_is.log",when="midnight", backupCount=30)
	#handler.setFormatter(formatter)
	#logger = logging.getLogger()
	#logger.addHandler(handler)
	#logger.setLevel(logging.INFO)
	#getCameraListRequestJson()
	streamingLiveCleaner()

	multicastLiveActiveDel = get_process_id("udp")
	if (len(multicastLiveActiveDel) > 0):
		for mLA in multicastLiveActiveDel:
			os.kill(mLA, 9)

if __name__ == '__main__':
	# init plus run
	app.run(host='0.0.0.0')