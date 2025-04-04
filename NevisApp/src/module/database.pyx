# coding=utf-8
import requests
import shutil
import time
import pyLogger
import globalvars
import xml.etree.ElementTree as ET
import json
import sys
import urllib
import os
from flask import Flask, jsonify, abort, make_response, request
import bcrypt
from bcrypt import hashpw, checkpw
#DB
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import desc, orm, exists, join, ForeignKey
from sqlalchemy.orm import relationship

webAppName = 'restServiceDB'
appDB = Flask(webAppName)
appDB.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////nevis_app/nevis_latest/db/nevis.db'
appDB.config['SECRET_KEY'] = "X}vn`fUF.?AEMq?[F,D_3*RgTx,M4f6-nrJGtjp;"
appDB.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(appDB)

class ViewUser(db.Model):
	user_id = db.Column(db.Integer, primary_key = True)
	active = db.Column(db.Integer)
	email = db.Column(db.String(255))
	name = db.Column(db.String(255))
	last_name = db.Column(db.String(255))
	password = db.Column(db.String(255))
	role_id = db.Column(db.Integer, primary_key = True, nullable=False)
	role = db.Column(db.String(255))

class User(db.Model):
	__tablename__ = 'user'
	user_id = db.Column(db.Integer, primary_key = True)
	active = db.Column(db.Integer)
	email = db.Column(db.String(255))
	name = db.Column(db.String(255))
	last_name = db.Column(db.String(255))
	password = db.Column(db.String(255))

	role_id = relationship("UserRole", primaryjoin='and_(User.user_id == UserRole.user_id)')

class UserRole(db.Model):
	__tablename__ = 'user_role'
	user_id = db.Column(db.Integer, ForeignKey('user.user_id'), primary_key = True, nullable=False)
	role_id = db.Column(db.Integer, ForeignKey('role.role_id'), primary_key = True, nullable=False)

class Role(db.Model):
	role_id = db.Column(db.Integer, primary_key = True)
	role = db.Column(db.String(255))
	#Rrole = db.relationship('UserRole', foreign_keys='UserRole.user_id')
	
class UserAttempts(db.Model):
	__tablename__ = 'user_attempts'
	user_id = db.Column(db.Integer, ForeignKey('user.user_id'), primary_key = True, nullable=False)
	attempts = db.Column(db.Integer)
	last_modified = db.Column(db.Integer)
	

def loginCheck(email, password):
	try:
		users = ViewUser.query.all()
		check = False
		for user in users:
			#print(password.encode('utf8'))
			#print(user.password.encode('utf8'))
			if user.email == email and user.role_id == 1 and bcrypt.checkpw(password.encode('utf8'), user.password.encode('utf8')):
				check = True
		return check
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		result = {'status': 'ko', 'msg': '*** Exception loginCheck: {} - {}'.format(e, exc_tb.tb_lineno)}
		#databaseLogger.sendLogMsg('DATABASE', 'ERROR', '*** Exception getDBRole: {} - {}'.format(e, exc_tb.tb_lineno))
		return result	
		
def getUserAttempts(emailTemp):
	try:
		userAttempts = UserAttempts.query.filter_by(user_id=emailTemp).first()
		return userAttempts
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		result = {'status': 'ko', 'msg': '*** Exception getUser: {} - {}'.format(e, exc_tb.tb_lineno)}
		#databaseLogger.sendLogMsg('DATABASE', 'ERROR', '*** Exception getDBRole: {} - {}'.format(e, exc_tb.tb_lineno))
		return result

def putUserAttempts(user_id_temp, attempts_temp, last_modified_temp):
	try:
		#CHECKS
		if user_id_temp is None or user_id_temp == '' \
					or attempts_temp is None \
					or last_modified_temp is None:
			return False;
		
		rowUserAttempt = UserAttempts(user_id=user_id_temp, attempts=attempts_temp, last_modified=last_modified_temp)
		db.session.add(rowUserAttempt)
		db.session.flush()
		
		db.session.commit()
		#response = {
		#	'status': 'OK',
		#	'msg': 'Operazione avvenuta con successo.'
		#}
		return True
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		print ('*** Exception getUser: {} - {}'.format(e, exc_tb.tb_lineno))
		return False
		
def updateUsersAttempts(dataTemp):
	user_id_temp = dataTemp['user_id']
		
	db.session.query(UserAttempts).filter_by(user_id=user_id_temp).update(dataTemp)
	db.session.flush()
	
	db.session.commit()

def getUser(emailTemp):
	try:
		user = db.session.query(User).filter_by(email=emailTemp).first()
		return user
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		result = {'status': 'ko', 'msg': '*** Exception getUser: {} - {}'.format(e, exc_tb.tb_lineno)}
		#databaseLogger.sendLogMsg('DATABASE', 'ERROR', '*** Exception getDBRole: {} - {}'.format(e, exc_tb.tb_lineno))
		return result

def getUsers():
	try:
		users = ViewUser.query.all()
		userset = []
		for user in users:
			userset.append({'active': str(user.active), 'email':user.email, 'name':user.name, 'last_name':user.last_name, 'role': user.role})
		result = {'status': 'OK', 'list': userset}
		return result
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		result = {'status': 'ko', 'msg': '*** Exception getUsers: {} - {}'.format(e, exc_tb.tb_lineno)}
		#databaseLogger.sendLogMsg('DATABASE', 'ERROR', '*** Exception getDBRole: {} - {}'.format(e, exc_tb.tb_lineno))
		return result

def putUsers(activeTemp, emailTemp, nameTemp, last_nameTemp, passwordTemp, roleTemp):
	try:
		if activeTemp is None or activeTemp == '' or \
						emailTemp is None or emailTemp == '' or \
						nameTemp is None or nameTemp == '' or \
						last_nameTemp is None or last_nameTemp == '' or \
						passwordTemp is None or passwordTemp == '' or \
						roleTemp is None or roleTemp == '':
			response = {
				'status': 'KO',
				'msg': 'Tutti i campi sono obbligatori'
			}
			return response

		if activeTemp.isdigit() != True:
			response = {
				'status': 'KO',
				'msg': 'Il campo active non è corretto.'
			}
			return response

		if int(activeTemp) > 1:
			response = {
				'status': 'KO',
				'msg': 'Il campo active non è corretto.'
			}
			return response

		# verifico che non sia possibile inserire un ruolo amministratore e che il Role passato sia presente sul DB
		roleID = RoleToID(roleTemp)
		if roleID is None:
			response = {
				'status': 'KO',
				'msg': 'Il Role scelto non è corretto.'
			}
			return response

		# if  roleTemp != 'ROLE_AGENT' and \
		#	roleTemp != 'ROLE_PROFILE' and \
		#	roleTemp != 'ROLE_SECURITY':
		#	response = {
		#		'status': 'KO',
		#		'msg': 'Il Role scelto non è corretto.'
		#	}
		#	return json.dumps(response)

		# if 2 < int(roleTemp) > 4:
		#		response = {
		#			'status': 'KO',
		#			'msg': 'Il Role scelto non è corretto.'
		#		}
		#		return json.dumps(response)

		# Verifico che non siano presenti utenti con la stessa email
		user = User.query.filter_by(email=emailTemp).first()
		if not user:
			passwordTemp = genPass(passwordTemp).encode('utf-8')
			rowUser = User(active=activeTemp, email=emailTemp, name=nameTemp, last_name=last_nameTemp, password=passwordTemp)
			db.session.add(rowUser)
			db.session.flush()

			rowRole = UserRole(user_id=rowUser.user_id, role_id=roleID )
			db.session.add(rowRole)
			db.session.flush()

			db.session.commit()
			response = {
				'status': 'OK',
				'msg': 'Operazione avvenuta con successo.'
			}
			return response
			#return make_response(jsonify(response)), 201
		else:

			response = {
				'status': 'KO',
				'msg': 'Utente già esistente.'
			}
			return response
		# return make_response(jsonify(response)), 202
	except Exception as e:
		response = {
			'status': 'KO',
			'msg': 'Operazione fallita: ' + str(e)
		}
		return response
		#return make_response(jsonify(response)), 401

def updateUsers(dataTemp):
	try:
		emailTemp = dataTemp['email']
		roleID = None

		if emailTemp is None or emailTemp == '':
			response = {
				'status': 'KO',
				'msg': 'Il campo email è obbligatorio.'
			}
			return response

		# Verifico che siano presenti utenti con la stessa email
		user = ViewUser.query.filter_by(email=emailTemp).first()
		if user is None:
			response = {
				'status': 'KO',
				'msg': 'Utente non presente.'
			}
			return response
			# return make_response(jsonify(response)), 202

		if 'active' in dataTemp:
			if dataTemp['active'].isdigit() != True:
				response = {
					'status': 'KO',
					'msg': 'Il campo active non è corretto.'
				}
				return response

			if int(dataTemp['active']) > 1:
				response = {
					'status': 'KO',
					'msg': 'Il campo active non è corretto.'
				}
				return response

		if 'password' in dataTemp:
			dataTemp['password'] = genPass(dataTemp['password'])

		if 'user_id' in dataTemp:
			response = {
				'status': 'KO',
				'msg': 'Non puoi modificare il campo ID Utente'
			}
			return response

		if 'role' in dataTemp:
			roleID = RoleToID(dataTemp['role'])
			if roleID is None or int(user.role_id) == 1 and int(roleID) != 1:
				response = {
					'status': 'KO',
					'msg': 'Il Role scelto non è corretto.'
				}
				return response

			# cancello l elemento role dal json
			del dataTemp['role']

		db.session.query(User).filter_by(email=emailTemp).update(dataTemp)
		#rowUser = User(active=activeTemp, email=emailTemp, name=nameTemp, last_name=last_nameTemp, password=passwordTemp)
		#db.session.update(rowUser)
		db.session.flush()

		if roleID:
			db.session.query(UserRole).filter_by(user_id=user.user_id).update({'role_id':roleID})
			db.session.flush()

		db.session.commit()

		response = {
			'status': 'OK',
			'msg': 'Operazione avvenuta con successo.'
		}

		return response

	except Exception as e:
		#str(e)
		response = {
			'status': 'KO',
			'msg': 'Operazione fallita: ' + str(e)
		}
		return response

def deleteUsers(dataTemp):
	try:
		emailTemp = dataTemp['email']
		if emailTemp is None or emailTemp == '':
			response = {
				'status': 'KO',
				'msg': 'Il campo email è obbligatorio.'
			}
			return response

		# Verifico che siano presenti utenti con la stessa email
		user = ViewUser.query.filter_by(email=emailTemp).first()
		if user is None:
			response = {
				'status': 'KO',
				'msg': 'Utente non presente.'
			}
			return response
			# return make_response(jsonify(response)), 202

		if user.role_id == 1:
			response = {
				'status': 'KO',
				'msg': 'Operazione non consentita.'
			}
			return response

		db.session.query(UserRole).filter_by(user_id=user.user_id).delete()
		db.session.flush()

		db.session.query(User).filter_by(email=emailTemp).delete()
		db.session.flush()

		db.session.commit()

		response = {
			'status': 'OK',
			'msg': 'Operazione avvenuta con successo.'
		}

		return response
		# return make_response(jsonify(response)), 201

	except Exception as e:
		#str(e)
		response = {
			'status': 'KO',
			'msg': 'Operazione fallita: ' + str(e)
		}
		return response

def getUserRole():
	try:
		users_role = UserRole.query.all()
		users_roleset = []
		for user_role in users_role:
			users_roleset.append({'user_id': user_role.user_id, 'role_id': user_role.role_id})
		result = {'status': 'OK', 'list': users_roleset}
		return result
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		result = {'status': 'ko', 'msg': '*** Exception getconnectionDB: {} - {}'.format(e, exc_tb.tb_lineno)}
		# databaseLogger.sendLogMsg('DATABASE', 'ERROR', '*** Exception getDBRole: {} - {}'.format(e, exc_tb.tb_lineno))
		return result

def checkRow(table, field, value):
	if db.session.query(table).filter(field == value).first() != None:
		#User exist
		statusCheck = 1
	else:
		#User not exist
		statusCheck = 0
	return statusCheck

#Verifica che il Role sia presente sul DB e ritorna ID di riferimento
def RoleToID(r):
	if  r != 'ROLE_AGENT' and r != 'ROLE_POLFER' and r != 'ROLE_SECURITY':
		return None
	else:
		findIdRole = db.session.query(Role.role_id).filter(Role.role == r).first()
		return findIdRole[0]

def genPass(pw):
	ROUNDS = 10
	pw_hash = bcrypt.hashpw(pw.encode('utf-8'), bcrypt.gensalt(prefix=b"2a",rounds=ROUNDS))
	return pw_hash

# used for testing
if __name__ == "__main__":

	#start_time = time.time()
	'''
	userList =  db.session.query(User.user_id,
								 User.email,
								 Role.role
								 ) \
		.join(UserRole, User.user_id == UserRole.user_id) \
		.join(Role, UserRole.role_id == Role.role_id)
	'''


	#inserimento = putUsers('1', 'claudiocaccamo8@test.it', 'Claudio', 'Caccamo', 'nevis', 'ROLE_SECURITY')
	#print inserimento

	#table, table.field, value
	#test = getCheckRow(User, User.name, "Nevis")
	#print test
	#print '==========='
	#print getUsers()
	#print "==========="
	#print getUserRole()
	#imagePath = getSnapshot(videoSourceId)
	#active=activeTemp, email=emailTemp, name=nameTemp, last_name=last_nameTemp, password=passwordTemp
	#data = {'role_id':'ROLE_AGENT', 'active': '0', 'email': 'claudiocaccamo6@test.it' }
	#data = {'name':'Mario', 'email': 'claudiocaccamo6@test.it', 'active':'1', 'last_name':'TEST', 'password':'nevis1' }
	#print updateUsers(data)

	#data = {'email': 'claudiocaccamo6@test.it'}
	#print deleteUsers(data)

	#print("*** Execution time {} seconds".format(time.time() - start_time))