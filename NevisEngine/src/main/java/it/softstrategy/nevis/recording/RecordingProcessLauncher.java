/**
 * 
 */
package it.softstrategy.nevis.recording;

import java.io.IOException;
import java.util.concurrent.Callable;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.zeroturnaround.exec.ProcessExecutor;
import org.zeroturnaround.exec.StartedProcess;
import org.zeroturnaround.process.PidUtil;

import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.model.RecordingConfigurationEntry;
import it.softstrategy.nevis.util.NevisFileSystemUtil;

/**
 * @author lgalati
 *
 *
 * DEPRECATED
 */
public class RecordingProcessLauncher implements Callable<RecordingProcessLaunchResult> {
	
	
	private static final Logger LOG = LogManager.getLogger(RecordingProcessLauncher.class.getName());

	
	private final NevisConfiguration configuration;
	
	
	private RecordingConfigurationEntry recordingConfiguration;
	private int slotId;
	
	
	//Constructor
	public RecordingProcessLauncher(RecordingConfigurationEntry recordingConfiguration, int slotId) {
		this.recordingConfiguration = recordingConfiguration;
		this.slotId = slotId;
		
		configuration = new NevisConfigurationImpl();
	}

	@Override
	public RecordingProcessLaunchResult call() throws Exception {
		
		RecordingProcessLaunchResult result = new RecordingProcessLaunchResult();
		
		String executablePath = configuration.getRecordingsExecutablePath();
		
		//TODO: how can we understand if the camera is onvif compliant? 
//		String slotFolder = String.format("%03d", slotId) + recordingConfiguration.getId() +  "_M_" + recordingConfiguration.getEncoder();
		String slotFolder = NevisFileSystemUtil.slotFolderName(recordingConfiguration, slotId);
		
		String cmd = executablePath + " " + slotFolder + " " + recordingConfiguration.getUrl() + " " + recordingConfiguration.getMacAddress();

		StartedProcess recordingProcess = null;
		try {
			recordingProcess = new ProcessExecutor().command("/bin/bash", "-c", cmd)
					.destroyOnExit()
					//.readOutput(true).redirectError(Slf4jStream.of("ThreadManager").asInfo())
					.start();
			
			int pid = PidUtil.getPid(recordingProcess.getProcess());
			LOG.info(
					String.format("Process with PID %d started to record the stream from %s, camera %s %s with ip %s on SLOT %s with profile %s",
						pid, recordingConfiguration.getVideoSourceId(), recordingConfiguration.getVendor(), recordingConfiguration.getModel(),
						recordingConfiguration.getIpAddress(), slotId, recordingConfiguration.getEncoder()
						)
					);
		} catch (IOException e) {
			LOG.error("Error while starting Registration", e);
		}
		
		result.setStartedProcess(recordingProcess);
		result.setRecordingConfiguration(recordingConfiguration);
						
		return result;
	}

}
