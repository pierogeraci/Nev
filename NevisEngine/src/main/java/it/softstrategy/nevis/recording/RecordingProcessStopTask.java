package it.softstrategy.nevis.recording;

import java.util.concurrent.Callable;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.zeroturnaround.process.PidProcess;
import org.zeroturnaround.process.ProcessUtil;
import org.zeroturnaround.process.Processes;

import it.softstrategy.nevis.model.Recording;

/**
 * @author lgalati
 *
 */
public class RecordingProcessStopTask implements Callable<Void> {
	
	private static final Logger LOG = LogManager.getLogger(RecordingProcessStopTask.class.getName());

//	private final NevisConfiguration configuration;
	private Recording recording;
	
	public RecordingProcessStopTask(Recording recording) {
//		configuration = new NevisConfigurationImpl();
		this.recording = recording;
	}
	

	@Override
	public Void call() throws Exception {

		PidProcess process = Processes.newPidProcess(recording.getPid());
		
		try {
			LOG.debug("Sending SIGTERM to recording process[" + recording.getPid() + "]");
			ProcessUtil.destroyGracefullyAndWait(process);
			LOG.info(
					String.format("Process with PID %d stopped to record the stream from %s on SLOT %s",
							recording.getPid(), recording.getVideoSourceId(),  recording.getSlotId())
					);
		} catch (Exception e) {
			LOG.error("Unexpected Exception while sending SIGTERM to recording process [" + recording.getPid() + "]" , e);
		} /*finally {
			RecListRestService service = new RecListRestService(configuration.getRecordingsDataSourceHost(), 
					configuration.getRecordingsDataSourcePort());
			service.deleteRecording(recording);
//			SlotsManagerSingleton.getInstance().deassociateSlot(recording.getVideoSourceId());
		}*/
		
		return null;
	}

}
