#title           :queries.py
#description     :Database Queries Module
#author          :Mario Squillace
#date            :20171221
#version         :1.4.0
#usage           :python nevis_is.py
#notes           :
#python_version  :2.7.9  
#==============================================================================

# -*- coding: utf-8 -*-
import sys
import os
import re
import cgi
import json
import xmltodict
import csv
import sys, os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine, MetaData, Table, and_, select

app = Flask(__name__)
engine = create_engine('sqlite:////nevis_app/nevis_latest/db/nevis.db', convert_unicode=True)
metadata = MetaData(bind=engine)

class dbClasses():
	def getcamsSettingsManualList(self):
		cam = Table('cam', metadata, autoload=True)
		con = engine.connect()
		result = engine.execute(cam.select(cam.c.is_manual == 'true'))
		camsManualList = []
		for row in result:
			camManualListDict = {
				'id': row.id_cam,
				'vendor': row.vendor,
				'model': row.model,
				'ipAddress': row.ip_address,
				'httpPort': row.http_port,
				'macAddress': row.mac_address,
				'isManual': row.is_manual,
				'isOnvif': row.is_onvif,
				'inputConnectors': row.input_connectors}
			camsManualList.append(camManualListDict)
		return camsManualList

#Prende il primo valore della tabella WHERE il campo è uguale al valore
#settings = sistema.select(sistema.c.is_manual == 'SETTINGS').execute().first()
#Prende i valori della tabella sistema WHERE sezione è uguale a SETTINGS e chiave è uguale a CONFIG_FOLDER
#result = engine.execute(sistema.select(and_(sistema.c.sezione == 'SETTINGS', sistema.c.chiave == 'CONFIG_FOLDER')))