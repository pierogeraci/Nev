package it.softstrategy.nevis.configuration;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Properties;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class DebianConfigurationSingleton {
	
	
	private static final Logger LOG = LogManager.getLogger(DebianConfigurationSingleton.class.getName());
	
	private Properties properties;
	private String nevisHomeFolder;
	private String propertyFilePath;
	
	//COSTRUTTUORE PRIVATO
	private DebianConfigurationSingleton() throws FileNotFoundException, IOException  {
		
		nevisHomeFolder = System.getenv("NEVIS_HOME");
		propertyFilePath = nevisHomeFolder + File.separator + "/conf" + File.separator + "config.ini";
		properties =  new Properties();
		properties.load(new FileInputStream(propertyFilePath));

	}

	private static class Helper {
		
		private final static DebianConfigurationSingleton INSTANCE;
		
		static {
			try {
				INSTANCE = new DebianConfigurationSingleton();
			} catch (Exception e) {
				LOG.error("Cannot load info from property file.", e);
				throw new RuntimeException("Cannot load info from property file.", e);
			}
		}
	}
	
	public static DebianConfigurationSingleton getInstance() {
		return Helper.INSTANCE;
	}
	
	
	// HOME FOLDER
	public String getHomeFolder() {
		return nevisHomeFolder;
	}
	
	// FOLDERS
	public String getConfigurationFolder() {
		return nevisHomeFolder + File.separator + "conf";
	}
	
	public String getLicenseFolder() {
		return nevisHomeFolder + File.separator + "license"; 
	}
	
	public String getWorkFolder() {
		return nevisHomeFolder + File.separator + "conf" + File.separator + "generated";
	}
	
	public String getWorkHistoryFolder() {
		return nevisHomeFolder + File.separator + "conf" + File.separator + "generated_history";
	}
	
	
	public String getRecordingsBaseFolder() {
		return "/nevis";
	}

	
	//PROPERTIES
	public Boolean isServerDiscoveryEnabled() {
		String stringPropValue = properties.getProperty("DISCOVERY_SERVER_ENABLED");
		return Boolean.parseBoolean(stringPropValue);
	}

	
	
	public String getServerDiscoveryStorageFilePath() {
		String fileName = properties.getProperty("DISCOVERY_SERVER_FILE_PATH");
		return nevisHomeFolder + File.separator + "conf" + File.separator + "generated" + File.separator + fileName;
	}

	
	
	public Boolean isOnvifDiscoveryEnabled() {
		String stringPropValue = properties.getProperty("DISCOVERY_NETWORK_ENABLED");
		return Boolean.parseBoolean(stringPropValue);
	}

	
	
	public Boolean isOnvifDiscoveryRepeatable() {
		String stringPropValue = properties.getProperty("DISCOVERY_NETWORK_RECURRENT");
		return Boolean.parseBoolean(stringPropValue);
	}

	
	
	public Integer getOnvifDiscoveryMaxTries() {
		String stringPropValue = properties.getProperty("DISCOVERY_NETWORK_MAX_TRIES");
		return Integer.parseInt(stringPropValue);
	}

	
	
	public Integer getOnvifDiscoverySocketTimeout() {
		String stringPropValue = properties.getProperty("DISCOVERY_NETWORK_SOCKET_TIMEOUT");
		return Integer.parseInt(stringPropValue);
	}

	
	
	public Long getOnvifDiscoveryPeriod() {
		String stringPropValue = properties.getProperty("DISCOVERY_NETWORK_PERIOD");
		return Long.parseLong(stringPropValue);
	}

	
	
	public String getOnvifDiscoveryStorageFilePath() {
		String fileName = properties.getProperty("DISCOVERY_NETWORK_LIST_CAMS_PATH");
		return nevisHomeFolder + File.separator + "conf" + File.separator + "generated" + File.separator + fileName;
	}

	
	
	public String getRecordingsStorageFilePath() {
		String fileName = properties.getProperty("REC_LIST");
		return nevisHomeFolder + File.separator + "conf" + File.separator + "generated" + File.separator + fileName;
	}

	
	
	public String getRecordingsExecutablePath() {
		String fileName = properties.getProperty("THREAD_REC_PATH");
		return nevisHomeFolder + File.separator + "bin" + File.separator + fileName;
	}

	
	
	public String getManualCamsFilePath() {
		String fileName = properties.getProperty("LIST_CAMS_MANUAL_FILE");
		return nevisHomeFolder + File.separator + "conf" + File.separator + fileName;
	}
	
	
	public String getManualCamsFileName() {
		return properties.getProperty("LIST_CAMS_MANUAL_FILE");
	}

	
	
	public String getUrlTemplateFilePath() {
		String fileName = properties.getProperty("DISCOVERY_NETWORK_LIST_CAMS_URL_PATH");
		return nevisHomeFolder + File.separator + "conf" + File.separator + fileName;
	}


	public Long getServerDiscoveryDuration() {
		String stringPropValue = properties.getProperty("DISCOVERY_SERVER_DURATION");
		return Long.parseLong(stringPropValue);
	}



	public String getCamsConfFilePath() {
		String fileName = properties.getProperty("CAMS_CONF");
		return nevisHomeFolder + File.separator + "conf" + File.separator + fileName;
	}



	public String getCamsConfFileName() {
		return properties.getProperty("CAMS_CONF");
	}



	public String getUpTimeServerFilePath() {
		String fileName = properties.getProperty("UPTIME_SERVER_FILE_NAME");
		return nevisHomeFolder + File.separator + "conf" + File.separator + "generated" + File.separator + fileName;
	}



	public String getMonitorToEngineQueuePath() {
		String folderName = properties.getProperty("QUEUE_FOLDER");
		return nevisHomeFolder + File.separator + "conf" + File.separator + "generated" + File.separator + folderName;
	}


	public String getNevisEngineFile() {
		return properties.getProperty("ENGINE_FILE");
	}


	public String getPartitionsConfFileName() {
		return properties.getProperty("PARTITIONS_CONF");
	}


	public String getPartitionsConfFilePath() {
		String fileName =  properties.getProperty("PARTITIONS_CONF");
		return nevisHomeFolder + File.separator + "conf" + File.separator + fileName;
	}


	public String getRecordingsDataSourceHost() {
		return properties.getProperty("REC_LIST_HOST");
	}


	public String getRecordingsDataSourcePort() {
		return properties.getProperty("REC_LIST_PORT");
	}


	public int getRecordingsCheckInMilliseconds() {
		int result = 0;
		
		try {
		 result = Integer.parseInt(properties.getProperty("REC_LIST_CHECK_TIME_MS"));
		} catch (NumberFormatException e) {
			LOG.error("Incorrect value for parameter 'Recording Check Time'",e);
		} finally {
			if ( result == 0  ) {
				result = 1000;
			}
		}
		
		return result;
		
	}



	

}
