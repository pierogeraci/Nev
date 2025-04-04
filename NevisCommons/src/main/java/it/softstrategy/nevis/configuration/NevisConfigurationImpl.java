package it.softstrategy.nevis.configuration;

/**
 * @author lgalati
 * 
 * see: https://stackoverflow.com/questions/2503489/design-pattern-for-one-time-loaded-configuration-properties
 *
 */
public class NevisConfigurationImpl implements NevisConfiguration {
	

	@Override
	public String getHomeFolder() {		
		return DebianConfigurationSingleton.getInstance().getHomeFolder();
	}
	
	@Override
	public String getLicenseFolder() {
		return DebianConfigurationSingleton.getInstance().getLicenseFolder();
	}
	
	@Override
	public String getWorkFolder() {
		return DebianConfigurationSingleton.getInstance().getWorkFolder() ;
	}
	
	@Override
	public String getWorkHistoryFolder() {
		return DebianConfigurationSingleton.getInstance().getWorkHistoryFolder() ;
	}
	
	@Override
	public String getConfigurationFolder(){
		return DebianConfigurationSingleton.getInstance().getConfigurationFolder();
	}

	
	@Override
	public String getRecordingsBaseFolder() {		
		return DebianConfigurationSingleton.getInstance().getRecordingsBaseFolder() ;
	}

	
	@Override
	public Boolean isServerDiscoveryEnabled() {		
		return DebianConfigurationSingleton.getInstance().isServerDiscoveryEnabled() ;
	}
	
	
	@Override
	public Long getServerDiscoveryDuration() {
		return DebianConfigurationSingleton.getInstance().getServerDiscoveryDuration();
	}

	
	@Override
	public String getServerDiscoveryStorageFilePath() {		
		return DebianConfigurationSingleton.getInstance().getServerDiscoveryStorageFilePath() ;
	}

	
	@Override
	public Boolean isOnvifDiscoveryEnabled() {		
		return DebianConfigurationSingleton.getInstance().isOnvifDiscoveryEnabled() ;
	}

	
	@Override
	public Boolean isOnvifDiscoveryRepeatable() {		
		return DebianConfigurationSingleton.getInstance().isOnvifDiscoveryRepeatable() ;
	}

	
	@Override
	public Integer getOnvifDiscoveryMaxTries() {		
		return DebianConfigurationSingleton.getInstance().getOnvifDiscoveryMaxTries() ;
	}

	
	@Override
	public Integer getOnvifDiscoverySocketTimeout() {		
		return DebianConfigurationSingleton.getInstance().getOnvifDiscoverySocketTimeout() ;
	}

	
	@Override
	public Long getOnvifDiscoveryPeriod() {		
		return DebianConfigurationSingleton.getInstance().getOnvifDiscoveryPeriod() ;
	}

	
	@Override
	public String getOnvifDiscoveryStorageFilePath() {		
		return DebianConfigurationSingleton.getInstance().getOnvifDiscoveryStorageFilePath() ;
	}

	//Not used anymore after the introduction of SERIALIZZATORE
//	@Override
//	public String getRecordingsStorageFilePath() {		
//		return DebianConfigurationSingleton.getInstance().getRecordingsStorageFilePath()  ;
//	}

	
	@Override
	public String getRecordingsExecutablePath() {		
		return DebianConfigurationSingleton.getInstance().getRecordingsExecutablePath() ;
	}

	
	@Override
	public String getManualCamsFilePath() {		
		return DebianConfigurationSingleton.getInstance().getManualCamsFilePath() ;
	}
	
	@Override
	public String getManualCamsFileName() {
		return DebianConfigurationSingleton.getInstance().getManualCamsFileName() ;
	}

	
	@Override
	public String getUrlTemplateFilePath() {		
		return DebianConfigurationSingleton.getInstance().getUrlTemplateFilePath() ;
	}

	@Override
	public String getCamsConfFilePath() {
		return DebianConfigurationSingleton.getInstance().getCamsConfFilePath();
	}

	@Override
	public String getCamsConfFileName() {
		return DebianConfigurationSingleton.getInstance().getCamsConfFileName();
	}

	@Override
	public String getUpTimeServerFilePath() {
		return DebianConfigurationSingleton.getInstance().getUpTimeServerFilePath();
	}

	@Override
	public String getMonitorToEngineQueuePath() {
		return DebianConfigurationSingleton.getInstance().getMonitorToEngineQueuePath();
	}

	@Override
	public String getNevisEngineFile() {
		return DebianConfigurationSingleton.getInstance().getNevisEngineFile();
		
	}

	@Override
	public String getPartitionsConfFileName() {
		return DebianConfigurationSingleton.getInstance().getPartitionsConfFileName();
	}

	@Override
	public String getPartitionsConfFilePath() {
		return DebianConfigurationSingleton.getInstance().getPartitionsConfFilePath();
	}

	@Override
	public String getRecordingsDataSourceHost() {
		return DebianConfigurationSingleton.getInstance().getRecordingsDataSourceHost();
	}

	@Override
	public String getRecordingsDataSourcePort() {
		return DebianConfigurationSingleton.getInstance().getRecordingsDataSourcePort();
	}

	@Override
	public int getRecordingsCheckInMilliseconds() {
		return DebianConfigurationSingleton.getInstance().getRecordingsCheckInMilliseconds();
	}	

}
