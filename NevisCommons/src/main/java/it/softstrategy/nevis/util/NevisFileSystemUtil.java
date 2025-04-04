
package it.softstrategy.nevis.util;

import it.softstrategy.nevis.model.RecordingConfigurationEntry;

/**
 * @author lgalati
 *
 */
public class NevisFileSystemUtil {
	
	
	public static String slotFolderName(RecordingConfigurationEntry configurationEntry, int slotId) {
		String slotFolderName = "";
		
		if (configurationEntry != null)  {
			String quality = configurationEntry.getQuality().toUpperCase();
			String videoSourceId = configurationEntry.getVideoSourceId();
//			slotFolderName = String.format("%03d", slotId) +  "_M_" + videoSourceId + "_" + quality;
			slotFolderName = String.valueOf(slotId) +  "_M_" + videoSourceId + "_" + quality;
		} else {
			//TODO: implementare l'else in cui si logga un messaggio di errore
		}
		
		
		return slotFolderName;
	}

}
