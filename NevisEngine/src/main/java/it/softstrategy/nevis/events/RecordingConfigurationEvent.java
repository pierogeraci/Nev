/**
 * 
 */
package it.softstrategy.nevis.events;

import java.util.List;

import it.softstrategy.nevis.model.RecordingConfigurationEntry;

/**
 * @author lgalati
 *
 */
public class RecordingConfigurationEvent {
	
//	public static final int RESET = 0;
//	public static final int UPDATE = 1;
	
	public enum Type {
		RESET,
		START,
		UPDATE
	}
	

	private Type type;
	private List<RecordingConfigurationEntry> configurationEntries;

	
	public RecordingConfigurationEvent(Type type, List<RecordingConfigurationEntry> configurationEntries) {
		//TODO: inserire il check sul campo type
		this.type = type;
		this.configurationEntries = configurationEntries;
	}


	public Type getType() {
		return type;
	}


	public List<RecordingConfigurationEntry> getConfigurationEntries() {
		return configurationEntries;
	}
	
	
}
