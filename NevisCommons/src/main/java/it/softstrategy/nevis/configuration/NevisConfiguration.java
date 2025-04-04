
package it.softstrategy.nevis.configuration;

/**
 * @author lgalati
 * 
 * see: https://stackoverflow.com/questions/2503489/design-pattern-for-one-time-loaded-configuration-properties
 *
 */
public interface NevisConfiguration {
	
	
	//FILE SYSTEM CONFIGURATION
	String getHomeFolder();
	String getConfigurationFolder();
	String getLicenseFolder();
	String getWorkFolder();
	String getWorkHistoryFolder();
	String getRecordingsBaseFolder();
	String getNevisEngineFile();
	
	
	//SERVER DISCOVERY CONFIGURATION
	Boolean isServerDiscoveryEnabled();
	String getServerDiscoveryStorageFilePath();
	Long getServerDiscoveryDuration();
	
	//ONVIF DISCOVERY CONFIGURATION
	Boolean isOnvifDiscoveryEnabled();
	Boolean isOnvifDiscoveryRepeatable();
	Integer getOnvifDiscoveryMaxTries();
	Integer getOnvifDiscoverySocketTimeout();
	Long getOnvifDiscoveryPeriod();
	String getOnvifDiscoveryStorageFilePath();
	
	
	//RECORDINGS BASE CONFIGURATION
//	String getRecordingsStorageFilePath();
	String getRecordingsExecutablePath();
	String getRecordingsDataSourceHost();
	String getRecordingsDataSourcePort();
	int getRecordingsCheckInMilliseconds();
	
	
	//Other CONFIGURATION
	String getManualCamsFilePath();
	String getManualCamsFileName();
	String getUrlTemplateFilePath();
	
	//Configurazione Esterna
	String getCamsConfFilePath();
	String getCamsConfFileName();
	
	//Partitions Configuration
	String getPartitionsConfFileName();
	String getPartitionsConfFilePath();
	
	//UPTIME SERVER
	String getUpTimeServerFilePath();
	String getMonitorToEngineQueuePath();
	
	
	

}
