package it.softstrategy.nevis.externalconf;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import org.apache.commons.io.FilenameUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import it.softstrategy.nevis.AppHelper;
import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.events.RecordingConfigurationEvent;
import it.softstrategy.nevis.model.RecordingConfigurationEntry;
import it.softstrategy.nevis.util.FileWatcherListener;

/**
 * @author lgalati
 *
 */
public class NevisRecordingsConfigurationManager implements FileWatcherListener, Runnable {

	private final static Logger LOG = LogManager.getLogger(NevisRecordingsConfigurationManager.class.getName());
	
	
	private final NevisConfiguration configuration;
	
	
	private List<RecordingConfigurationEntry> recordingsConfiguration;
	private Thread thread;
	private Thread fileWatcherThread;
	private FileWatcher fileWatcher;
	private boolean isConfigurationChanged;
	
	
	public NevisRecordingsConfigurationManager() {		
		configuration = new NevisConfigurationImpl();
		isConfigurationChanged = false;
	}
	
	public void start(boolean restart) {

		if (!restart) {
			//Check if the file already exists
			File f = new File (configuration.getCamsConfFilePath());
			if ( f.exists() ) {
				//Se il file esiste, carico il contenuto
				// e lo "spedisco" al gestore delle Registrazioni
				notifyConfigurationChange(false);
			}
		}

		//In caso di riavvio
		if (fileWatcher != null) {
			fileWatcher.removeFileWatcherListener(this);
		}

		//Avvio/Riavvio
		String folderPath = FilenameUtils.getFullPath(configuration.getCamsConfFilePath());
		String fileName = configuration.getCamsConfFileName();
		fileWatcher = new FileWatcher(folderPath, fileName);
		fileWatcher.addFileWatcherListener(this);
		fileWatcherThread = new Thread(fileWatcher);
		fileWatcherThread.setName("File " + fileName + " Watcher");
		fileWatcherThread.start();
		
		thread = new Thread(this);
		thread.setName("NevisRecordingsConfigurationManager Thread");
		thread.start();

	}
	
	public void stop() {
		
		if (thread != null) {
			thread.interrupt();
		}
		
		if (fileWatcherThread != null) {
			fileWatcherThread.interrupt();
		}
		
	}
	
	public boolean isWorking() {
		
		if (thread != null && fileWatcherThread != null) {
			return thread.isAlive() && fileWatcherThread.isAlive();
		}
		
		return false;
	}
	
	
	@Override
	public synchronized void fileChanged() {
		
		if (!isConfigurationChanged) {
			isConfigurationChanged = true;
		}
		
//		loadRecordingsConfiguration();
//		
//			
//		RecordingConfigurationEvent event = 
//				new RecordingConfigurationEvent(RecordingConfigurationEvent.RESET, getRecordingsConfiguration());
//		
//		AppHelper.getInstance().getEventBus().post(event);
//		LOG.debug("invio configurazione");
	}
	
	
	public List<RecordingConfigurationEntry> getRecordingsConfiguration() {
		return new ArrayList<>(validateExternalConfiguration(this.recordingsConfiguration)) ;
		
	}
	
	@Override
	public void run() {
		//Se il file di configurazione è cambiato
		while (true) {
			boolean notify = false;
			synchronized (this) {
				notify = isConfigurationChanged;
			}
			
			if (notify) {
				notifyConfigurationChange(true);
				synchronized (this) {
					isConfigurationChanged = false;
				}
			}
			
			
			try {
				TimeUnit.MILLISECONDS.sleep(2000);
//				LOG.debug("Configuration Change Check ended! Going to sleep");
			} catch (InterruptedException e) {
				LOG.error("TODO: inserire messaggio", e);
				//e.printStackTrace();
				break;
			}
		}
	}
	
	
	private void notifyConfigurationChange(boolean reset) {
		loadRecordingsConfiguration();

		RecordingConfigurationEvent event = 
				new RecordingConfigurationEvent(
											reset ? RecordingConfigurationEvent.Type.RESET : RecordingConfigurationEvent.Type.START, 
											getRecordingsConfiguration()
											);

		AppHelper.getInstance().getEventBus().post(event);
		LOG.debug("invio configurazione");
	}
	
	private void loadRecordingsConfiguration() {
		String filePath = configuration.getCamsConfFilePath();

		ObjectMapper mapper = new ObjectMapper();
		File f = new File(filePath);

		List<RecordingConfigurationEntry> entries = new ArrayList<>();

		try {
			JsonNode root = mapper.readTree(f);
			JsonNode cameraNode = root.path("camera");

			if(cameraNode.isArray()) {
				for (JsonNode node : cameraNode) {
					//Check node size null
					if (node.size()>1){
						RecordingConfigurationEntry entry = new RecordingConfigurationEntry();
						entry.setAudio(node.path("audio").asBoolean());
						entry.setDepth(node.path("depthRec").asInt());
						entry.setDescription(node.path("description").asText());
						entry.setEncoder(node.path("encoder").asText());
						entry.setIpAddress(node.path("ipAddress").asText());
						entry.setMacAddress(node.path("macAddress").asText());
						entry.setModel(node.path("model").asText());
						entry.setPassword(node.path("password").asText());
						entry.setQuality(node.path("quality").asText());
						entry.setSensorId(node.path("sensorId").asInt());
						entry.setUrl(node.path("url").asText());
						entry.setUrlLive(node.path("urlLive").asText());
						entry.setUsername(node.path("username").asText());
						entry.setVendor(node.path("vendor").asText());
						entry.setVideoSourceId(node.path("videoSourceId").asText());
						entries.add(entry);	
					}
				}
			} else {
				LOG.warn("Incorrect configuration file format!");
			}
		} catch (JsonProcessingException e) {
			LOG.error("Error while parsing the Json file " + filePath , e);
			//TODO: inviare un messaggio a SNMP?
		} catch (IOException e) {
			LOG.error("Unexpected IOException.", e);
			//TODO: inviare un messaggio a SNMP?
		}


		this.recordingsConfiguration = entries;
		LOG.debug("La nuova configurazione contiene  " + recordingsConfiguration.size() + " elementi.");
	}
	
	
	private List<RecordingConfigurationEntry> validateExternalConfiguration(List<RecordingConfigurationEntry> inEntries) {
		LOG.debug("Validating external configuration");
		List<RecordingConfigurationEntry> outEntries = new ArrayList<>();
		
		Set<String> videoSourcesSet = new HashSet<>();
		for (RecordingConfigurationEntry conf: inEntries) {
			if ( !videoSourcesSet.contains(conf.getVideoSourceId()) ) {
				videoSourcesSet.add(conf.getVideoSourceId());
				outEntries.add(conf);
			} else {
				LOG.warn("Found a duplicate configuration for videoSource " + conf.getVideoSourceId());
				LOG.warn("For every videosource only a configuration is accepted!!! ");
			}
		}
		
		
		return outEntries;
	}

}
