import hashlib
import subprocess
import sys

if __name__ == '__main__':

    # Vars
    filePath = '/etc/shadow'
    existingPassphrase = sys.argv[1]
    rootPassphrase = None
    outputPassphrase = None

    # Open Shadow File
    with open(filePath, 'r') as inputFile:    # extract root hash

        for line in inputFile:

            if 'root' in line:

                #lineEncoded = line.encode('utf-8')

                print('*** Line with root: {}'.format(line))
                rootPassphrase = line.split(':')[1]
                print('*** Root Passphrase: {}'.format(rootPassphrase))

    # double sha
    if rootPassphrase is not None:

        # encrypt
        tempPassphrase = hashlib.sha512(rootPassphrase.encode('utf-8')).hexdigest()
        outputPassphrase = hashlib.sha512(tempPassphrase.encode('utf-8')).hexdigest()
        print('*** outputPassphrase Passphrase: {}'.format(outputPassphrase))

    # insert passphrase
    if outputPassphrase is not None and existingPassphrase is not None:

        echoCommand = ['echo', '-e', existingPassphrase + '\\n' + outputPassphrase]
        cryptCommand = ['cryptsetup', 'luksAddKey', '/dev/sda3']

        print('*** Echo command: {}'.format(echoCommand))

        proc1 = subprocess.Popen(echoCommand, shell=False, stdout=subprocess.PIPE)
        proc2 = subprocess.Popen(cryptCommand, shell=False, stdin=proc1.stdout, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)

        proc1.stdout.close()  # Allow proc1 to receive a SIGPIPE if proc2 exits.
        out, err = proc2.communicate()

        print('*** out, err (Insert Passp): {} --- {}'.format(out, err))