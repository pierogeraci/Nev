import psutil
import json
import subprocess
from shutil import copy2
import os
import sys


def main():
    returnNegative = 'KO'
    returnPositive = 'OK'

    functionReturn = 'KO'

    try:

        # support variables
        poolName = 'nevisPool'
        poolMountPoint = '/nevis'
        poolMode = 'epmfs',
        type = ''
        outputFileName = 'partitions_conf.json'
        deviceName = ''
        primaryVar = ''
        numberOfDisks = 0
        deviceList = []
        luksUsersList = sys.argv[1]
        secretPassphrase = sys.argv[2]
        luksRootPassMultiRelativeDirPath = '/nevis_app/nevis_latest/conf'
        luksRootPassMultiRelativeFilePath = 'luksRootPassMulti'
        FNULL = open(os.devnull, 'w')

        templateDict = {
            'partitions': [
            ],
            'poolName': 'nevisPool',
            'poolMountPoint': '/nevis',
            'poolMode': 'epmfs',
            'type': ''
        }

        partitionsTemplate = {
            'luksName': '',
            'partitionName': '',
            'primary': '',
            'mapperName': '',
            'mountPoint': ''
        }

        luksNameTemplate = 'videocrypt'
        mapperNameTemplate = '/dev/mapper/'
        mountPointTemplate = '/mnt/'

        # display available partitions

        print('*** Partizioni disponibili ***')
        result = subprocess.Popen('blkid', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        outputBlkid = [x for x in result.stdout.readlines()]
        deviceListComplete = [x.split(':')[0] for x in outputBlkid]

        for element in outputBlkid:
            print('Nome Device: {} - Descrizione: {}'.format(element.split(':')[0], element.split(': ')[1]))

        print('*** Fine Lista ***')

        # input number of disks
        while True:

            numberOfDisks = raw_input('Inserire il numero dischi di registrazione: ')

            if numberOfDisks.isdigit():

                numberOfDisks = int(numberOfDisks)

                if numberOfDisks > 0:
                    break
                else:
                    print(
                    '*** ERRORE! Il numero dischi di registrazione deve essere un numero maggiore di zero, riprovare.')

            else:

                print('*** ERRORE! Il numero dischi di registrazione deve essere un numero, riprovare.')

        if numberOfDisks > 0:

            if numberOfDisks == 1:  # single disk

                # device name
                while True:

                    deviceName = raw_input('Inserire il Nome Device: ')
                    positiveResultCheckDeviceName = checkDeviceName(deviceName, deviceListComplete)

                    if positiveResultCheckDeviceName:
                        break
                    else:
                        print('*** ERRORE! Nome device errato, controllare se e\' in lista e riprovare')

                tempPartition = {
                    'luksName': luksNameTemplate,
                    'partitionName': str(deviceName),
                    'primary': 'True',
                    'mapperName': mapperNameTemplate + luksNameTemplate,
                    'mountPoint': mountPointTemplate + 'videocrypt'
                }

                # create output json
                templateDict['partitions'].append(tempPartition)
                #templateDict['type'] = 'single'
                templateDict['type'] = 'multiple'

            elif numberOfDisks > 1:  # multiple disks

                for i in range(numberOfDisks):
                    diskNumber = i+1
                    # device name
                    while True:

                        deviceName = ''
                        deviceName = raw_input('Inserire il Nome Device #' + str(diskNumber) + ' : ')
                        positiveResultCheckDeviceName = checkDeviceName(deviceName, deviceListComplete)

                        if positiveResultCheckDeviceName:
                            if deviceName not in deviceList:  # new device not in list
                                deviceList.append(deviceName)
                                break
                            else:
                                print('*** ERRORE! Nome device gia\' inserito')
                        else:
                            print('*** ERRORE! Nome device errato, controllare se e\' in lista e riprovare')

                    # primary
                    while True:

                        positiveResultPrimaryVar = False
                        primaryVar = ''
                        primaryVar = raw_input('Indicare se il disco e\' Primary (y/n): ')

                        if primaryVar.lower() == 'y' or primaryVar.lower() == 'yes':

                            primaryVar = 'True'
                            positiveResultPrimaryVar = True  # valid char

                        elif primaryVar.lower() == 'n' or primaryVar.lower() == 'no':

                            primaryVar = 'False'
                            positiveResultPrimaryVar = True  # valid char

                        if positiveResultPrimaryVar:
                            break
                        else:
                            print('*** ERRORE! Primary errato, inserire \'y\' o \'n\' - {}'.format(primaryVar))

                    tempPartition = {
                        'luksName': luksNameTemplate + str(i + 1),
                        'partitionName': str(deviceName),
                        'primary': str(primaryVar),
                        'mapperName': mapperNameTemplate + luksNameTemplate + str(i + 1),
                        'mountPoint': mountPointTemplate + luksNameTemplate + str(i + 1)
                    }

                    # add element to partitions
                    templateDict['partitions'].append(tempPartition)

                # variables in the main template
                templateDict['type'] = 'multiple'

            # write to file
            writeOutputJsonFile(outputFileName, templateDict)

            print('File {} scritto con successo'.format(outputFileName))

            # build encrypted partitions
            resultBuildLuks = buildEncryptedPartitions(templateDict, secretPassphrase)

            if resultBuildLuks == returnPositive:

                # run luks luksRootPassMulti

                # copy conf file to luksRootPassMulti directory
                currentDir = os.getcwd() + '/'
                #copy2(currentDir + outputFileName, luksRootPassMultiRelativeDirPath + outputFileName)

                # call luksRootPassMulti executable
                commandLuks = currentDir + luksRootPassMultiRelativeFilePath + ' ' + luksUsersList + ' ' + secretPassphrase
                resultLuks = subprocess.call(commandLuks, shell=True, stdout=FNULL)

                if resultLuks == 0:

                    functionReturn = returnPositive

                else:

                    functionReturn = returnNegative
            else:

                functionReturn = returnNegative

            return functionReturn

        else:

            print('*** ERRORE! Numero di dischi errato: {}'.format(numberOfDisks))
            return returnNegative


    except Exception as ex:

        # handle unexpected script errors
        print('*** Exception Unhandled error luksCreartion: {}'.format(ex))
        return returnNegative


def checkDeviceName(deviceName, deviceListComplete):  # check if partition is in partition list

    result = False

    for element in deviceListComplete:

        if deviceName == element:
            result = True
            break

    return result


def writeOutputJsonFile(outputFileName, templateDict):
    with open(outputFileName, 'w+') as outputFile:
        json.dump(templateDict, outputFile, indent=4, sort_keys=True)


def buildEncryptedPartitions(templateDict, secretPassphrase):
    result = 'OK'

    for element in templateDict['partitions']:

        print('Creazione ed apertura partizione luks: {}'.format(element['partitionName']))

        # first command, create luks container
        command1 = 'echo ' + secretPassphrase + ' | cryptsetup -v luksFormat ' + element['partitionName']
        result1 = subprocess.call(command1, shell=True)

        if result1 == 0:  # ok

            # second command, open container
            command2 = 'echo ' + secretPassphrase + ' | cryptsetup luksOpen ' + element['partitionName'] + ' ' + element[
                'luksName']
            result2 = subprocess.call(command2, shell=True)

            if result2 == 0:  # ok

                # third command, create ext4 file system
                command3 = 'mkfs.ext4 ' + element['mapperName']
                result3 = subprocess.call(command3, shell=True)

                if result3 == 0:

                    command4 = 'mkdir -p ' + element['mountPoint'] + ' && mount ' + element['mapperName'] + ' ' + \
                               element['mountPoint'] + ' && mount -a'
                    result4 = subprocess.call(command4, shell=True)

                    if result4 == 0:

                        result = 'OK'

                    else:

                        result = 'KO'
                        break

                else:

                    result = 'KO'
                    break

            else:

                result = 'KO'
                break

        else:

            result = 'KO'
            break

    return result


if __name__ == '__main__':
    main()

'''
	partitionsTemplate = {
							"luksName" : "videocrypt1",
							"partitionName": "/dev/sdb1",
							"primary": "True",
							"mapperName": "/dev/mapper/videocrypt1",
							"mountPoint": "/mnt/videocrypt1"
						}	

'''