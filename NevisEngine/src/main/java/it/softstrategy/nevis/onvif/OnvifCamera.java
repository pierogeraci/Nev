package it.softstrategy.nevis.onvif;

import java.io.Serializable;

public class OnvifCamera implements Serializable {

	
	private static final long serialVersionUID = 1L;
	
	private String name;
    private String vendor;
    private String model;
    private String ipAddress;
    private int httpPort;
    private String macAddress;
    private String firstSeen;
	
    
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

	@Override
	public String toString() {
		return "OnvifCamera [name=" + name + ", vendor=" + vendor + ", model=" + model + ", ipAddress=" + ipAddress
				+ ", httpPort=" + httpPort + ", macAddress=" + macAddress + ", firstSeen=" + firstSeen + "]";
	}

	public String[] toStringArray() {
		String[] fieldsString  = new String[5];
		
		fieldsString[0] = this.getIpAddress();
		fieldsString[1] = this.getMacAddress();
		fieldsString[2] = this.getVendor();
		fieldsString[3] = this.getModel();
		fieldsString[4] = this.getFirstSeen();
		
		
		return fieldsString;
	}
	
	

}
