package it.softstrategy.nevis.model;

import java.util.Date;

import org.simpleframework.xml.Element;
import org.simpleframework.xml.Root;

@Root(name="Entry")
public class SlotsArchiveEntry {
	
	@Element(name="SlotId")
	private Integer slotId;
	
	@Element(name="IpAddress", required=false)
	private String ipAddress;
	
	@Element(name="MacAddress", required=false)
	private String macAddress;

	@Element(name="VideoSourceId", required=false)
	private String videoSourceId;
	
	@Element(name="Timestamp", required=false)
	private Date timestamp;
	
	private boolean used;
	

	public Integer getSlotId() {
		return slotId;
	}

	public void setSlotId(Integer slotId) {
		this.slotId = slotId;
	}

	public String getIpAddress() {
		return ipAddress;
	}

	public void setIpAddress(String ipAddress) {
		this.ipAddress = ipAddress;
	}

	public String getMacAddress() {
		return macAddress;
	}

	public void setMacAddress(String macAddress) {
		this.macAddress = macAddress;
	}
	
	public String getVideoSourceId() {
		return videoSourceId;
	}

	public void setVideoSourceId(String videoSourceId) {
		this.videoSourceId = videoSourceId;
	}
	
	public Date getTimestamp() {
		return timestamp;
	}

	public void setTimestamp(Date timestamp) {
		this.timestamp = timestamp;
	}

	public boolean isUsed() {
		return used;
	}

	public void setUsed(boolean used) {
		this.used = used;
	}

	@Override
	public String toString() {
		return "SlotsArchiveEntry ["
				+ "slotId=" + slotId + ", videoSourceId=" + videoSourceId + ", used=" + used + "] \n";
	}
	
	

}
