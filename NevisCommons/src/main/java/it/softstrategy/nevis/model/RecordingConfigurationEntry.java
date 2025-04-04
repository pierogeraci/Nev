
package it.softstrategy.nevis.model;

/**
 * @author lgalati
 *
 */
public class RecordingConfigurationEntry {
	
	private boolean audio;
	private int depth;
	private String description;
	private String encoder;
	private String ipAddress;
	private String macAddress;
	private String model;
	private String password;
	private String quality;
	private int sensorId;
	private String url;
	private String urlLive;
	private String username;
	private String vendor;
	private String videoSourceId;
	
	
	public boolean isAudio() {
		return audio;
	}
	
	public void setAudio(boolean audio) {
		this.audio = audio;
	}
	
	
	public int getDepth() {
		return depth;
	}
	
	public void setDepth(int depth) {
		this.depth = depth;
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
	
	
	public String getModel() {
		return model;
	}
	
	public void setModel(String model) {
		this.model = model;
	}
	
	
	public String getPassword() {
		return password;
	}
	
	public void setPassword(String password) {
		this.password = password;
	}
	

	public String getQuality() {
		return quality;
	}

	public void setQuality(String quality) {
		this.quality = quality;
	}

	
	public int getSensorId() {
		return sensorId;
	}

	public void setSensorId(int sensorId) {
		this.sensorId = sensorId;
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
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		RecordingConfigurationEntry other = (RecordingConfigurationEntry) obj;
		if (audio != other.audio)
			return false;
		if (depth != other.depth)
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
		if (password == null) {
			if (other.password != null)
				return false;
		} else if (!password.equals(other.password))
			return false;
		if (quality == null) {
			if (other.quality != null)
				return false;
		} else if (!quality.equals(other.quality))
			return false;
		if (sensorId != other.sensorId)
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
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + (audio ? 1231 : 1237);
		result = prime * result + depth;
		result = prime * result + ((description == null) ? 0 : description.hashCode());
		result = prime * result + ((encoder == null) ? 0 : encoder.hashCode());
		result = prime * result + ((ipAddress == null) ? 0 : ipAddress.hashCode());
		result = prime * result + ((macAddress == null) ? 0 : macAddress.hashCode());
		result = prime * result + ((model == null) ? 0 : model.hashCode());
		result = prime * result + ((password == null) ? 0 : password.hashCode());
		result = prime * result + ((quality == null) ? 0 : quality.hashCode());
		result = prime * result + sensorId;
		result = prime * result + ((url == null) ? 0 : url.hashCode());
		result = prime * result + ((urlLive == null) ? 0 : urlLive.hashCode());
		result = prime * result + ((username == null) ? 0 : username.hashCode());
		result = prime * result + ((vendor == null) ? 0 : vendor.hashCode());
		result = prime * result + ((videoSourceId == null) ? 0 : videoSourceId.hashCode());
		return result;
	}

	

	@Override
	public String toString() {
		return "RecordingConfigurationEntry [audio=" + audio + ", depth=" + depth + ", description=" + description
				+ ", encoder=" + encoder + ", ipAddress=" + ipAddress + ", macAddress=" + macAddress + ", model="
				+ model + ", password=**********" + /*password +*/ ", quality=" + quality + ", sensorId=" + sensorId + ", url=" + url
				+ ", urlLive=" + urlLive + ", username=" + username + ", vendor=" + vendor + ", videoSourceId=" + videoSourceId + "]";
	}

	public boolean isConfigurationOf (Recording r) {
		//TODO: use the recording/camera id to make the compare in the future
		
		return this.ipAddress.equals(r.getIp()) 
				&& this.encoder.equals(r.getEncoder())
				&& this.ipAddress.equals(r.getIp())
				&& this.macAddress.equals(r.getMac())
				&& this.model.equals(r.getModel())
				&& this.quality.equals(r.getQuality())
				&& this.url.equals(r.getUrl())
				&& this.urlLive.equals(r.getUrlLive())
				&& this.vendor.equals(r.getVendor())
				&& this.videoSourceId.equals(r.getVideoSourceId());
				
	}
	
	
	
	
}
