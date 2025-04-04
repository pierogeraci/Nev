#!/usr/bin/python

import logging
import logging.handlers as handlers
import module.database
import sys


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# create a file handler
#handler = logging.FileHandler('/nevis_app/nevis_latest/log/user_mantainer_job.log')
#handler.setLevel(logging.INFO)

# create a rotating file handler
logHandler = handlers.RotatingFileHandler('/nevis_app/nevis_latest/log/user_mantainer_job.log', maxBytes=50000, backupCount=2)
logHandler.setLevel(logging.INFO)

# create console handler
consoleLogger = logging.StreamHandler()
consoleLogger.setLevel(logging.INFO)

# create a logging format
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
#handler.setFormatter(formatter)
logHandler.setFormatter(formatter)
consoleLogger.setFormatter(formatter)

# add the handlers to the logger
#logger.addHandler(handler)
logger.addHandler(logHandler)
logger.addHandler(consoleLogger)

def main():
	try:
		logger.info ("Avvio procedura automatica di abilitazione utenze amministrative bloccate.")
		usersDict = module.database.getUsers()
		for user in usersDict['list']:
			#print (user)
			if user['role'] == 'ROLE_ADMIN' and user['active'] == '0':
				logger.info ('Utenza amministrativa:' + str(user) + ' disabilitata. Avvio abilitazione...')
				
				userFromDb = module.database.getUser(user['email'])
				#Azzero il numero di tentativi
				params = {}
				params['user_id'] = userFromDb.user_id
				params['attempts'] = 0
				module.database.updateUsersAttempts(params)
			
				#Abilitazione utenza
				userparams = {}
				userparams['email'] = userFromDb.email
				userparams['name'] = userFromDb.name
				userparams['last_name'] = userFromDb.last_name
				#userparams['password'] = user.password
				userparams['active'] = '1'
				
				ret = module.database.updateUsers(userparams)
				
				if ret['status'] == 'OK':
					logger.info('...abilitazione terminata')
				else:
					logger.error('...errore durante abilitazione utenza :' + ret['msg'])
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		logger.error('*** Exception main: {} - {}'.format(e, exc_tb.tb_lineno))
	
if __name__=="__main__":
	main()