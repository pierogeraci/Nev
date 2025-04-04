package it.softstrategy.nevis.recording;

import org.zeroturnaround.exec.StartedProcess;

import it.softstrategy.nevis.model.RecordingConfigurationEntry;

/**
 * @author lgalati
 *
 *
 *	DEPRECATED
 */
public class RecordingProcessLaunchResult {
	
	private RecordingConfigurationEntry recordingConfiguration;
	private StartedProcess startedProcess;
	
	
	public RecordingConfigurationEntry getRecordingConfiguration() {
		return recordingConfiguration;
	}
	
	public void setRecordingConfiguration(RecordingConfigurationEntry recordingConfiguration) {
		this.recordingConfiguration = recordingConfiguration;
	}
	
	
	public StartedProcess getStartedProcess() {
		return startedProcess;
	}
	
	public void setStartedProcess(StartedProcess startedProcess) {
		this.startedProcess = startedProcess;
	}
	
	

}
