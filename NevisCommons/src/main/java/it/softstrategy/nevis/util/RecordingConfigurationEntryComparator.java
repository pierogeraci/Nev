package it.softstrategy.nevis.util;

import java.util.Comparator;

import it.softstrategy.nevis.model.RecordingConfigurationEntry;

/**
 * @author lgalati
 *
 */
public class RecordingConfigurationEntryComparator implements Comparator<RecordingConfigurationEntry> {


	@Override
	public int compare(RecordingConfigurationEntry o1, RecordingConfigurationEntry o2) {
		int result = o1.getVideoSourceId().compareTo(o2.getVideoSourceId());
		
//		if (result == 0) {
//			result =  o1.getIpAddress().compareTo(o2.getIpAddress());
//		}
		
		return result;
	}

}
