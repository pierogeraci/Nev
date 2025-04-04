package it.softstrategy.nevis.model;

/**
 * @author lgalati
 *
 */
public class Slot {
	
	
	private int id;
	
	private String type;
	
	private String videoSourceId;
	
	private String quality;

	
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	
	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	
	public String getVideoSourceId() {
		return videoSourceId;
	}

	public void setVideoSourceId(String videoSourceId) {
		this.videoSourceId = videoSourceId;
	}

	
	public String getQuality() {
		return quality;
	}

	public void setQuality(String quality) {
		this.quality = quality;
	}

	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + id;
		result = prime * result + ((quality == null) ? 0 : quality.hashCode());
		result = prime * result + ((type == null) ? 0 : type.hashCode());
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
		Slot other = (Slot) obj;
		if (id != other.id)
			return false;
		if (quality == null) {
			if (other.quality != null)
				return false;
		} else if (!quality.equals(other.quality))
			return false;
		if (type == null) {
			if (other.type != null)
				return false;
		} else if (!type.equals(other.type))
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
		return "Slot [id=" + id + ", type=" + type + ", videoSourceId=" + videoSourceId + ", quality=" + quality + "]";
	}
	
	
	

}
