package it.softstrategy.nevis.recording;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map.Entry;
import java.util.SortedMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.google.common.eventbus.Subscribe;

import it.softstrategy.nevis.AppHelper;
import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.events.RecordingConfigurationEvent;
import it.softstrategy.nevis.model.Recording;
import it.softstrategy.nevis.model.RecordingConfigurationEntry;
import it.softstrategy.nevis.rest.RecListRestService;
import it.softstrategy.nevis.slot.SlotsManagerSingleton;

/**
 * @author lgalati
 *
 */
public class RecordingProcessManager  {
	
	private static final Logger LOG = LogManager.getLogger(RecordingProcessManager.class.getName());
	
	
	private final NevisConfiguration configuration;

	
	private final Object LOCK = new Object();

	

	public RecordingProcessManager() {
		configuration = new NevisConfigurationImpl();
	}
	
	
	public void initialize() {
		AppHelper.getInstance().getEventBus().register(this);
		
	}
	
	@Subscribe
	public void handleRecordingConfigurationEvent(RecordingConfigurationEvent event) {
		LOG.info("Received new configuration");
		if (event == null) {
			LOG.warn("Event null!!! I'm doing nothing");
			return;
		}
		
		if (event.getType() == RecordingConfigurationEvent.Type.RESET) {
			synchronized (LOCK) {
				try {
					reset(event.getConfigurationEntries());
				} catch (InterruptedException e) {
					LOG.error("Unexpected InterruptedException while Resetting the Recordings", e);
					//TODO: inviare un allarme SNMP o REST?
				} catch (IOException e) {
					LOG.error("Cannot complete Reset of the Recordgins. Unexpected IOException!!!", e);
					//TODO: inviare un allarme SNMP o REST?
				}
			}
		} else if (event.getType() == RecordingConfigurationEvent.Type.START
				||event.getType() == RecordingConfigurationEvent.Type.UPDATE) {
			synchronized (LOCK) {
				try {
					startRecordings(event.getConfigurationEntries());//Senza fare nessun check?
				} catch (InterruptedException e) {
					LOG.error("Unexpected InterruptedException while Resetting the Recordings", e);
					//TODO: inviare un allarme SNMP o REST?
				} catch (IOException e) {
					LOG.error("Cannot complete Reset of the Recordgins. Unexpected IOException!!!", e);
					//TODO: inviare un allarme SNMP o REST?
				}
			}
		}
	}

	
	
	//--------------------------------------------------------------------------------
	//		METODI PRIVATI
	//--------------------------------------------------------------------------------
	//TODO: dovrei usare il synchronized anche qui? Creo que no!!!
	private void reset(List<RecordingConfigurationEntry> entries) throws InterruptedException, IOException {
		LOG.info("Starting to work on new configurations...");

		//STEP 1: Kill all the current Started  Recording Processes
		stopRecordings();
			
			
		startRecordings(entries);

	}
		
	
	private void stopRecordings() throws IOException, InterruptedException {
		LOG.info("Stopping current Recording Processes");
		LOG.info("Cleaning REC_LIST");
		List<Recording> currentRecordings = loadRecordings();
		
		//Prima di terminare i processi svuoto il REC_LIST.xml
		//per evitare anomalia doppi processi di registrazione
		RecListRestService service = new RecListRestService(configuration.getRecordingsDataSourceHost(), 
																configuration.getRecordingsDataSourcePort());
		service.addRecordings(new ArrayList<>());
		
		//Rimuove dopo l'esito dei test
//		TimeUnit.MILLISECONDS.sleep(configuration.getRecordingsCheckInMilliseconds() + 500);
		
		if (!currentRecordings.isEmpty()) {
			ThreadPoolExecutor executor = (ThreadPoolExecutor) Executors.newFixedThreadPool(currentRecordings.size()); 

			List<RecordingProcessStopTask> stopTasks = new ArrayList<>();
			
			for (Recording currRecording : currentRecordings) {
				stopTasks.add(new RecordingProcessStopTask(currRecording));
			}
			
			
			List<Future<Void>> futureList = executor.invokeAll(stopTasks);
			
			executor.shutdown();
//			executor.awaitTermination(1, TimeUnit.HOURS);
			
			for (Future<Void> future: futureList) {
				try {
					future.get();
				} catch (ExecutionException e) {
					LOG.error("RecordingProcessStopTask ended with exception!", e);
				}
			}
			
						
		} else {
			LOG.info("No RecordingProcess to terminate!");
		}
		
		//Decommenta per assicurarti al 100% della pulizia del REC_LIST.xml
//		service.addRecordings(new ArrayList<>());
	}
	
	private void startRecordings(List<RecordingConfigurationEntry> entries) throws IOException, InterruptedException {
		
		//Associate slot to recording
		SortedMap<RecordingConfigurationEntry, Integer> toLaunchWithSlot = SlotsManagerSingleton.getInstance().associateSlots(entries);

		if (!toLaunchWithSlot.isEmpty()) {

			ThreadPoolExecutor executor = (ThreadPoolExecutor) Executors.newFixedThreadPool(toLaunchWithSlot.size()); 

			//Launch new Recording Processes
			List<RecordingProcessStartTask> startTasks = new ArrayList<>();
			for (Entry<RecordingConfigurationEntry, Integer> entry : toLaunchWithSlot.entrySet()) {	
				RecordingConfigurationEntry recordingConf = entry.getKey();
				Integer slotId = entry.getValue();
				if (slotId != null) {
					LOG.debug("Creating start task for " + recordingConf.getVideoSourceId() + " - slotid = " + slotId);
					startTasks.add(new RecordingProcessStartTask(recordingConf, slotId));
				}

			}
			List<Future<Recording>> resultList = executor.invokeAll(startTasks);
			executor.shutdown();
//			executor.awaitTermination(timeout, unit)


			//Manage new Started Recording Processes and
			List<Recording> newRecordings = new ArrayList<>();
			for (Future<Recording> futureResult : resultList) {
				try {
					Recording newRecording = futureResult.get();
					newRecordings.add(newRecording);
					LOG.debug("Retrieved new Recording Process: VIDEOSOURCE" + newRecording.getVideoSourceId() + " - SLOTID=" + newRecording.getSlotId() );
				} catch (ExecutionException e) {
					LOG.error("Unexpected ExecutionException", e);
				}
			}

			//Update REC_LIST.xml
			RecListRestService service = new RecListRestService(configuration.getRecordingsDataSourceHost(), 
																	configuration.getRecordingsDataSourcePort());
			service.addRecordings(newRecordings);
		}
		 
	}
	
	
	//PRIVATE UTILS METHODS
	
	private List<Recording> loadRecordings() throws IOException {
		RecListRestService service = new RecListRestService(configuration.getRecordingsDataSourceHost(), 
															 configuration.getRecordingsDataSourcePort());
		List<Recording> recordings = service.getRecordings();
		return recordings;
	}


}
