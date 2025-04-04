#!/usr/bin/python -u
import json
import sys
import requests
import globalvars
import pyLogger
import xml.etree.ElementTree as ET

snmpLogger = pyLogger.pyLoggerClass()
snmpLogger.sendLogMsg('SNMP', 'DEBUG','*** Log SNMP started...')

def loadFromXML():

    try:

        urlFotografia = ''

        # open ws conf
        tree = ET.parse(globalvars.NEVIS_CONFIG_XML)
        root = tree.getroot()

        for child in root:
            if child.get('key') == 'ws.endpoint.local.fotografia':
                urlFotografia = child.text

        return urlFotografia

    except Exception as ex:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        snmpLogger.sendLogMsg('SNMP', 'ERROR', '*** Exception SNMP loadFromXML: {} - line {}'.format(ex, exc_tb.tb_lineno))

def main():

    try:

        urlFotografia = loadFromXML()

        resp = requests.get(urlFotografia)
        jsonResp = resp.json()

        print(jsonResp['cpuPerc'])
        print(jsonResp['ramPerc'])
        print(jsonResp['spazioDiscoPerc'])
        print(jsonResp['spazioDiscoSlot'])
        print(jsonResp['numeroRegistrazioniAttive'])
        print(jsonResp['numeroRegistrazioniErrore'])
        print(jsonResp['numeroStreamUnicast'])
        print(jsonResp['numeroStreamMulticast'])
        print(jsonResp['ultimoPowerOff'])
        print(jsonResp['ultimoStartUp'])
        print(jsonResp['systemTime'])
        print(jsonResp['ntpTime'])
        print(jsonResp['ntpCode'])
        print(jsonResp['nevisVersion'])
        print(jsonResp['configVersion'])
        print(jsonResp['licenseFlag'])
        print(jsonResp['confDisksFlag'])
        print(jsonResp['disksFlag'])
        print(jsonResp['archiveFlag'])
        print(jsonResp['nevisEngineFlag'])

    except Exception as e:

        exc_type, exc_obj, exc_tb = sys.exc_info()
        snmpLogger.sendLogMsg('SNMP', 'ERROR', '*** Exception SNMP: {} - line {}'.format(e, exc_tb.tb_lineno))

if __name__ == '__main__':

    main()