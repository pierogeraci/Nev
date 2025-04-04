package it.softstrategy.nevis.model;

import org.simpleframework.xml.Attribute;
import org.simpleframework.xml.Element;
import org.simpleframework.xml.Root;

@Root(name="nevis-camera")
public class NevisCamera {
	
	@Attribute(required=false)
	private Integer id;

	@Element(required=false)
	private String name;
	
	@Element
    private String vendor;
	
	@Element
    private String model;
	
	@Element
    private String ipAddress;
	
	@Element(required=false)
    private int httpPort;
	
	@Element
    private String macAddress;
	
	@Element(required=false)
    private String firstSeen;
	
	@Element(required=false)
    private String lastSeen;
	
	@Element
    private Boolean isOnvif;
	
	@Element
    private int inputConnectors;
    
	public Integer getId() {
		return id;
	}

	public void setId(Integer id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}
	
	public void setName(String name) {
		this.name = name;
	}
	
	public String getVendor() {
		return vendor;
	}
	
	public void setVendor(String vendor) {
		this.vendor = vendor;
	}
	
	
	public String getModel() {
		return model;
	}
	
	public void setModel(String model) {
		this.model = model;
	}
	
	public String getIpAddress() {
		return ipAddress;
	}
	
	public void setIpAddress(String ipAddress) {
		this.ipAddress = ipAddress;
	}
	
	public int getHttpPort() {
		return httpPort;
	}
	
	public void setHttpPort(int httpPort) {
		this.httpPort = httpPort;
	}
	
	public String getMacAddress() {
		return macAddress;
	}
	
	public void setMacAddress(String macAddress) {
		this.macAddress = macAddress;
	}
	public String getFirstSeen() {
		return firstSeen;
	}
	
	public void setFirstSeen(String firstSeen) {
		this.firstSeen = firstSeen;
	}
	
	public String getLastSeen() {
		return lastSeen;
	}
	
	public void setLastSeen(String lastSeen) {
		this.lastSeen = lastSeen;
	}
	
	public Boolean getIsOnvif() {
		return isOnvif;
	}
	public void setIsOnvif(Boolean isOnvif) {
		this.isOnvif = isOnvif;
	}
	
	public int getInputConnectors() {
		return inputConnectors;
	}
	
	public void setInputConnectors(int inputConnectors) {
		this.inputConnectors = inputConnectors;
	}
	
	@Override
	public String toString() {
		return "NevisCamera [name " + name + ", vendor " + vendor + ", model " + model + ", ipAddress " + ipAddress
				+ ", httpPort " + httpPort + ", macAddress " + macAddress + ", firstSeen " + firstSeen + ", lastSeen "
				+ lastSeen + ", isOnvif " + isOnvif + ", inputConnectors " + inputConnectors + "]";
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((ipAddress == null) ? 0 : ipAddress.hashCode());
		result = prime * result + ((macAddress == null) ? 0 : macAddress.hashCode());
		result = prime * result + ((model == null) ? 0 : model.hashCode());
		result = prime * result + ((vendor == null) ? 0 : vendor.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		NevisCamera other = (NevisCamera) obj;
		if (ipAddress == null) {
			if (other.ipAddress != null)
				return false;
		} else if (!ipAddress.equals(other.ipAddress))
			return false;
		if (macAddress == null) {
			if (other.macAddress != null)
				return false;
		} else if (!macAddress.equals(other.macAddress))
			return false;
		if (model == null) {
			if (other.model != null)
				return false;
		} else if (!model.equals(other.model))
			return false;
		if (vendor == null) {
			if (other.vendor != null)
				return false;
		} else if (!vendor.equals(other.vendor))
			return false;
		return true;
	}

//	@Override
//	public boolean equals(Object obj) {
//		if (this == obj)
//			return true;
//		if (obj == null)
//			return false;
//		if (getClass() != obj.getClass())
//			return false;
//		NevisCamera other = (NevisCamera) obj;
//		if (macAddress == null) {
//			if (other.macAddress != null)
//				return false;
//		} else if (!macAddress.equals(other.macAddress))
//			return false;
//		if (model == null) {
//			if (other.model != null)
//				return false;
//		} else if (!model.equals(other.model))
//			return false;
//		if (vendor == null) {
//			if (other.vendor != null)
//				return false;
//		} else if (!vendor.equals(other.vendor))
//			return false;
//		return true;
//	}
	
	
    
    
	
}
