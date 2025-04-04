package it.softstrategy.nevis.util;



import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.model.Recording;
import it.softstrategy.nevis.model.RecordingConfigurationEntry;
import it.softstrategy.nevis.model.Slot;

/**
 * @author lgalati
 *
 */
public class ConversionUtil {
	
	private static final Logger LOG = LogManager.getLogger(ConversionUtil.class.getName());
	
	
	public static Recording createRecording(RecordingConfigurationEntry recordingConfiguration, int pid, int slotId) {
		
		if (recordingConfiguration == null)
			return null;
		
		Recording ret = new Recording();
		ret.setDepthRec(recordingConfiguration.getDepth());
		ret.setEncoder(recordingConfiguration.getEncoder());
		ret.setIp(recordingConfiguration.getIpAddress());
		ret.setIsOnvif(false);
		ret.setMac(recordingConfiguration.getMacAddress());
		ret.setModel(recordingConfiguration.getModel());
		ret.setPassword(recordingConfiguration.getPassword());
		ret.setDescription(recordingConfiguration.getDescription());
		ret.setPid(pid);
		
		ret.setQuality(recordingConfiguration.getQuality());
		
		ret.setSensorId(recordingConfiguration.getSensorId());
		
//		Integer intSlotId = SlotsManagerSingleton.getInstance().getCurrentSlotId(recordingConfiguration);
		ret.setSlotFolder(NevisFileSystemUtil.slotFolderName(recordingConfiguration, slotId));
//		String strSlotId = String.format("%03d", slotId); //whatif intSlotId = null
		String strSlotId = String.valueOf(slotId);
		ret.setSlotId(strSlotId);
		
		ret.setStatus("Not Running");
		ret.setUrl(recordingConfiguration.getUrl());
		ret.setUrlLive(recordingConfiguration.getUrlLive());
		ret.setUsername(recordingConfiguration.getUsername());
		ret.setVendor(recordingConfiguration.getVendor());
		ret.setVideoSourceId(recordingConfiguration.getVideoSourceId());
		
		return ret;
	}
	
	
	public static Slot createSlot(String slotFolderName) {
		
		Slot ret = null;
		
		if (slotFolderName != null && slotFolderName.length() > 0) {
			String[] array = slotFolderName.split("_", 4);
			
			try {
				String slotId = array[0];
				String type = array[1];
				String videoSourceId = array[2];
				String quality = array[3];
				
				Slot newSlot = new Slot();
				newSlot.setId(Integer.parseInt(slotId));
				newSlot.setType(type);
				newSlot.setQuality(quality);
				newSlot.setVideoSourceId(videoSourceId);
				ret = newSlot;
			} catch (IndexOutOfBoundsException | NumberFormatException e) {
				LOG.error("Unexpected slot folder name [" + slotFolderName + "]",e);
			}
		}
		
		return ret;
	}

}
