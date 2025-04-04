package it.softstrategy.nevis.recording;

import java.util.concurrent.Callable;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.zeroturnaround.exec.ProcessExecutor;
import org.zeroturnaround.exec.StartedProcess;
import org.zeroturnaround.process.PidUtil;

import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.model.Recording;
import it.softstrategy.nevis.model.RecordingConfigurationEntry;
import it.softstrategy.nevis.util.ConversionUtil;
import it.softstrategy.nevis.util.NevisFileSystemUtil;

/**
 * @author lgalati
 *
 */
public class RecordingProcessStartTask implements Callable<Recording> {

	private static final Logger LOG = LogManager.getLogger(RecordingProcessStartTask.class.getName());
	
	
	
	private final NevisConfiguration configuration;
	
	
	private RecordingConfigurationEntry recordingConfiguration;
	private int slotId;
	
	
	public RecordingProcessStartTask(RecordingConfigurationEntry recordingConfiguration, int slotId) {
		this.recordingConfiguration = recordingConfiguration;
		this.slotId = slotId;
		
		configuration = new NevisConfigurationImpl();
	}


	@Override
	public Recording call() throws Exception {

		String executablePath = configuration.getRecordingsExecutablePath();

		//TODO: how can we understand if the camera is onvif compliant? 
		String slotFolder = NevisFileSystemUtil.slotFolderName(recordingConfiguration, slotId);

		String cmd = executablePath + " " + slotFolder + " " + recordingConfiguration.getUrl() + " " + recordingConfiguration.getMacAddress();


		StartedProcess recordingProcess = new ProcessExecutor().command("/bin/bash", "-c", cmd)
				.destroyOnExit()
				//.readOutput(true).redirectError(Slf4jStream.of("ThreadManager").asInfo())
				.start();

		int pid = PidUtil.getPid(recordingProcess.getProcess());
		LOG.trace(String.format("Process with PID %d started", pid));
		LOG.info(
				String.format("Recording Process started to record the stream from %s, camera %s %s with ip %s on SLOT %s with profile %s",
						recordingConfiguration.getVideoSourceId(), recordingConfiguration.getVendor(), recordingConfiguration.getModel(),
						recordingConfiguration.getIpAddress(), slotId, recordingConfiguration.getEncoder()
						)
				);

		Recording recording = ConversionUtil.createRecording(recordingConfiguration, pid, slotId);

		//E se aggiornassi qui il REC_LIST.xml?

		return recording;
	}

}
