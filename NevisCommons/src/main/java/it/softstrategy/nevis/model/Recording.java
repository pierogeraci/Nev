package it.softstrategy.nevis.model;

import org.simpleframework.xml.Attribute;
import org.simpleframework.xml.Element;
import org.simpleframework.xml.Root;

@Root(name="Cam")
public class Recording {

	
	@Element(name="DepthRec")
	private Integer depthRec;
	
	@Element(name="Description")
	private String description;
	
	@Element(name="Encoder")
	private String encoder;
	
	@Element(name="Ip")
	private String ip;
	
	@Element(name="Mac")
	private String mac;
	
	@Element(name="Model")
	private String model;

	@Element(name="IsOnvif")
	private Boolean isOnvif;
	
	@Element(name="Password")
	private String password;
	
	@Element(name="Pid")
	private int pid;
	
	@Element (name="Quality")
	private String quality;
	
	@Element(name="SensorId")
	private Integer sensorId;
	
	@Element(name="SlotFolder")
	private String slotFolder;
	
	@Attribute(name="id")
	private String slotId;
	
	@Element(name="Status")
	private String status;
	
	@Element(name="Url", data=true)
	private String url;

	@Element(name="UrlLive", data=true)
	private String urlLive;
	
	@Element(name="Username")
	private String username;
	
	@Element(name="Vendor")
	private String vendor;
	
	@Element(name="VideoSourceId")
	private String videoSourceId;
	

	public Integer getDepthRec() {
		return depthRec;
	}

	public void setDepthRec(Integer depthRec) {
		this.depthRec = depthRec;
	}
	
	
	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getEncoder() {
		return encoder;
	}

	public void setEncoder(String encoder) {
		this.encoder = encoder;
	}


	public String getIp() {
		return ip;
	}

	public void setIp(String ip) {
		this.ip = ip;
	}


	public String getMac() {
		return mac;
	}

	public void setMac(String mac) {
		this.mac = mac;
	}


	public String getModel() {
		return model;
	}

	public void setModel(String model) {
		this.model = model;
	}


	public Boolean getIsOnvif() {
		return isOnvif;
	}

	public void setIsOnvif(Boolean isOnvif) {
		this.isOnvif = isOnvif;
	}


	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}


	public int getPid() {
		return pid;
	}

	public void setPid(int pid) {
		this.pid = pid;
	}


	public String getQuality() {
		return quality;
	}

	public void setQuality(String quality) {
		this.quality = quality;
	}

	
	public Integer getSensorId() {
		return sensorId;
	}

	public void setSensorId(Integer sensorId) {
		this.sensorId = sensorId;
	}


	public String getSlotFolder() {
		return slotFolder;
	}

	public void setSlotFolder(String slotFolder) {
		this.slotFolder = slotFolder;
	}


	public String getSlotId() {
		return slotId;
	}

	public void setSlotId(String slotId) {
		this.slotId = slotId;
	}


	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}


	public String getUrl() {
		return url;
	}

	public void setUrl(String url) {
		this.url = url;
	}
	
	public String getUrlLive() {
		return urlLive;
	}

	public void setUrlLive(String urlLive) {
		this.urlLive = urlLive;
	}


	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}


	public String getVendor() {
		return vendor;
	}

	public void setVendor(String vendor) {
		this.vendor = vendor;
	}


	public String getVideoSourceId() {
		return videoSourceId;
	}

	public void setVideoSourceId(String videoSourceId) {
		this.videoSourceId = videoSourceId;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((depthRec == null) ? 0 : depthRec.hashCode());
		result = prime * result + ((description == null) ? 0 : description.hashCode());
		result = prime * result + ((encoder == null) ? 0 : encoder.hashCode());
		result = prime * result + ((ip == null) ? 0 : ip.hashCode());
		result = prime * result + ((isOnvif == null) ? 0 : isOnvif.hashCode());
		result = prime * result + ((mac == null) ? 0 : mac.hashCode());
		result = prime * result + ((model == null) ? 0 : model.hashCode());
		result = prime * result + ((password == null) ? 0 : password.hashCode());
		result = prime * result + pid;
		result = prime * result + ((quality == null) ? 0 : quality.hashCode());
		result = prime * result + ((sensorId == null) ? 0 : sensorId.hashCode());
		result = prime * result + ((slotFolder == null) ? 0 : slotFolder.hashCode());
		result = prime * result + ((slotId == null) ? 0 : slotId.hashCode());
		result = prime * result + ((status == null) ? 0 : status.hashCode());
		result = prime * result + ((url == null) ? 0 : url.hashCode());
		result = prime * result + ((urlLive == null) ? 0 : urlLive.hashCode());
		result = prime * result + ((username == null) ? 0 : username.hashCode());
		result = prime * result + ((vendor == null) ? 0 : vendor.hashCode());
		result = prime * result + ((videoSourceId == null) ? 0 : videoSourceId.hashCode());
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
		Recording other = (Recording) obj;
		if (depthRec == null) {
			if (other.depthRec != null)
				return false;
		} else if (!depthRec.equals(other.depthRec))
			return false;
		if (description == null) {
			if (other.description != null)
				return false;
		} else if (!description.equals(other.description))
			return false;
		if (encoder == null) {
			if (other.encoder != null)
				return false;
		} else if (!encoder.equals(other.encoder))
			return false;
		if (ip == null) {
			if (other.ip != null)
				return false;
		} else if (!ip.equals(other.ip))
			return false;
		if (isOnvif == null) {
			if (other.isOnvif != null)
				return false;
		} else if (!isOnvif.equals(other.isOnvif))
			return false;
		if (mac == null) {
			if (other.mac != null)
				return false;
		} else if (!mac.equals(other.mac))
			return false;
		if (model == null) {
			if (other.model != null)
				return false;
		} else if (!model.equals(other.model))
			return false;
		if (password == null) {
			if (other.password != null)
				return false;
		} else if (!password.equals(other.password))
			return false;
		if (pid != other.pid)
			return false;
		if (quality == null) {
			if (other.quality != null)
				return false;
		} else if (!quality.equals(other.quality))
			return false;
		if (sensorId == null) {
			if (other.sensorId != null)
				return false;
		} else if (!sensorId.equals(other.sensorId))
			return false;
		if (slotFolder == null) {
			if (other.slotFolder != null)
				return false;
		} else if (!slotFolder.equals(other.slotFolder))
			return false;
		if (slotId == null) {
			if (other.slotId != null)
				return false;
		} else if (!slotId.equals(other.slotId))
			return false;
		if (status == null) {
			if (other.status != null)
				return false;
		} else if (!status.equals(other.status))
			return false;
		if (url == null) {
			if (other.url != null)
				return false;
		} else if (!url.equals(other.url))
			return false;
		if (urlLive == null) {
			if (other.urlLive != null)
				return false;
		} else if (!urlLive.equals(other.urlLive))
			return false;
		if (username == null) {
			if (other.username != null)
				return false;
		} else if (!username.equals(other.username))
			return false;
		if (vendor == null) {
			if (other.vendor != null)
				return false;
		} else if (!vendor.equals(other.vendor))
			return false;
		if (videoSourceId == null) {
			if (other.videoSourceId != null)
				return false;
		} else if (!videoSourceId.equals(other.videoSourceId))
			return false;
		return true;
	}

	@Override
	public String toString() {
		return "Recording [depthRec=" + depthRec + ", description=" + description + ", encoder=" + encoder + ", ip="
				+ ip + ", mac=" + mac + ", model=" + model + ", isOnvif=" + isOnvif + ", password=**********" //+ password
				+ ", pid=" + pid + ", quality=" + quality + ", sensorId=" + sensorId + ", slotFolder=" + slotFolder
				+ ", slotId=" + slotId + ", status=" + status + ", url=" + url + ", urlLive=" + urlLive 
				+ ", username=" + username + ", vendor=" + vendor + ", videoSourceId=" + videoSourceId + "]";
	}

	

	

	


}
