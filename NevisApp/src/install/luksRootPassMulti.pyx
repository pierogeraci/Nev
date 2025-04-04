import hashlib
import subprocess
import sys
import json

# Vars
filePath = '/etc/shadow'
#partitionsConfFile = '/nevis_app/nevis_latest/conf/partitions_conf.json'
partitionsConfFile = 'partitions_conf.json'
luksUsersList = sys.argv[1]
secretPassphrase = sys.argv[2]
# Lista di tutti gli utenti/password che devono essere aggiunti agli slot di Luks
ListUP = []

rootPassphrase = None
outputPassphrase = None
partitionsConfJson = None

def main():
	countEl = 0
	# Open partition json file
	with open(partitionsConfFile) as inputFileJson:    # extract root hash
		partitionsConfJson = json.load(inputFileJson)
		# print('*** Partition Conf File: {}'.format(partitionsConfJson))

	for v in luksUsersList.split('~'):
		# u, p = v.split(':')
		# ListUP.append({'user':u, 'pass':p, 'passphrase':''})
		ListUP.append({'user':v, 'passphrase':''})


	def addKey(user, passphrase):
		for element in partitionsConfJson['partitions']:
			print('*** Preparing partition {}'.format(element['partitionName']))

			echoCommand = ['echo', '-e', secretPassphrase + '\\n' + passphrase]
			cryptCommand = ['cryptsetup', 'luksAddKey', element['partitionName']]
			# cryptCommand = "echo -e '" + secretPassphrase + '\\n' + aK['passphrase'] +  "' | cryptsetup luksAddKey " + element['partitionName']

			print('*** Echo command: {}'.format(echoCommand))

			proc1 = subprocess.Popen(echoCommand, shell=False, stdout=subprocess.PIPE)
			proc2 = subprocess.Popen(cryptCommand, shell=False, stdin=proc1.stdout, stdout=subprocess.PIPE,
									 stderr=subprocess.PIPE)

			proc1.stdout.close()  # Allow proc1 to receive a SIGPIPE if proc2 exits.
			out, err = proc2.communicate()

			print('*** out partition {}: {}'.format(element['partitionName'], out))
			print('*** err partition {}: {}'.format(element['partitionName'], err))

	# Open Shadow File
	with open(filePath, 'r') as inputFile:    # extract root hash
		for line in inputFile:
			for n in range(len(ListUP)):
				if ListUP[n]['user'] in line:
					lineEncoded = line.encode('utf-8')
					print('*** Line with '+ListUP[n]['user']+': {}'.format(line))
					Passphrase = line.split(':')[1]
					print('*** '+ListUP[n]['user']+' Passphrase: {}'.format(Passphrase))

					# double sha
					if Passphrase is not None:
						# encrypt
						tempPassphrase = hashlib.sha512(Passphrase.encode('utf-8')).hexdigest()
						outputPassphrase = hashlib.sha512(tempPassphrase.encode('utf-8')).hexdigest()
						print('*** outputPassphrase '+ListUP[n]['user']+' Passphrase: {}'.format(outputPassphrase))

						ListUP[n].update({'passphrase':outputPassphrase})

						addKey(ListUP[n]['user'], outputPassphrase)

if __name__ == '__main__':
	main()

