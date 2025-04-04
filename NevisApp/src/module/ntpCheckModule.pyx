import ntplib
import time
import xml.etree.ElementTree as ET
import globalvars

def ntpCheckFunc(ntpServer):
	responseTimeNTP = 'Error' #default
	# init vars
	#ntpServer = getVarsFromXML()
	# init ntpLib
	c = ntplib.NTPClient()
	try:
		# call ntp server
		responseNTP = c.request(ntpServer, version=3)
		if responseNTP is not None:
			responseTimeNTP = time.strftime('%Y-%m-%d_%H-%M-%S', time.localtime(responseNTP.tx_time))
		else:
			responseTimeNTP = 'Error'
		#print responseTimeNTP
		return responseTimeNTP
	except Exception as ex:
		responseTimeNTP = 'Error'
		return responseTimeNTP
'''
def getVarsFromXML():

	ntpServer = 'it.pool.ntp.org'
	confFile = globalvars.NEVIS_CONFIG_XML

	tree1 = ET.parse(confFile)
	root1 = tree1.getroot()

	for child in root1:
		if child.get('key') == 'ntp.server':
			ntpServer = child.text
			print('*** ntpServer: {}'.format(ntpServer))

	return ntpServer
'''
if __name__ == '__main__':
	ntpCheckFunc()