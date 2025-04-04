package it.softstrategy.nevis.util;

import it.softstrategy.nevis.model.NevisCamera;
import it.softstrategy.nevis.model.UrlTemplateCamera;

public class NevisVideoSource {
	
	private String id;
	
	private NevisCamera nevisCamera;
	
	private Integer sensorId;
	
	private UrlTemplateCamera template;

	
	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	
	public NevisCamera getNevisCamera() {
		return nevisCamera;
	}

	public void setNevisCamera(NevisCamera nevisCamera) {
		this.nevisCamera = nevisCamera;
	}


	public Integer getSensorId() {
		return sensorId;
	}

	public void setSensorId(Integer sensorId) {
		this.sensorId = sensorId;
	}

	
	public UrlTemplateCamera getTemplate() {
		return template;
	}

	public void setTemplate(UrlTemplateCamera template) {
		this.template = template;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((id == null) ? 0 : id.hashCode());
		result = prime * result + ((nevisCamera == null) ? 0 : nevisCamera.hashCode());
		result = prime * result + ((sensorId == null) ? 0 : sensorId.hashCode());
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
		NevisVideoSource other = (NevisVideoSource) obj;
		if (id == null) {
			if (other.id != null)
				return false;
		} else if (!id.equals(other.id))
			return false;
		if (nevisCamera == null) {
			if (other.nevisCamera != null)
				return false;
		} else if (!nevisCamera.equals(other.nevisCamera))
			return false;
		if (sensorId == null) {
			if (other.sensorId != null)
				return false;
		} else if (!sensorId.equals(other.sensorId))
			return false;
		return true;
	}

	@Override
	public String toString() {
		return "NevisVideoSource [id=" + id + ", nevisCamera=" + nevisCamera + ", sensorId=" + sensorId + "]";
	}

	

	

}
