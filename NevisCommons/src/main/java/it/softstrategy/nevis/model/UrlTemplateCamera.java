package it.softstrategy.nevis.model;

import java.util.List;

import org.simpleframework.xml.Attribute;
import org.simpleframework.xml.Element;
import org.simpleframework.xml.ElementList;
import org.simpleframework.xml.Root;

@Root(name="camera")
public class UrlTemplateCamera {
	
	@Attribute(name="id")
	private String id;
	
	@Element
	private String model;
	
	@Element
	private String vendor;

	@Element(name="sensor_id")
	private Integer sensorId;
	
	@ElementList
	private List<UrlTemplateCameraProfile> profiles;
	

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	
	public String getModel() {
		return model;
	}

	public void setModel(String model) {
		this.model = model;
	}

	
	public Integer getSensorId() {
		return sensorId;
	}

	public void setSensorId(Integer sensorId) {
		this.sensorId = sensorId;
	}

	
	public String getVendor() {
		return vendor;
	}

	public void setVendor(String vendor) {
		this.vendor = vendor;
	}
	

	public List<UrlTemplateCameraProfile> getProfiles() {
		return profiles;
	}

	public void setProfiles(List<UrlTemplateCameraProfile> profiles) {
		this.profiles = profiles;
	}

	
	@Override
	public String toString() {
		return "UrlTemplateCamera ["
				+ "id =" + id
				+ ", model =" + model 
				+ ", sensorId =" + sensorId 
				+ ", vendor =" + vendor 
				+ ", profile =" + profiles 
				+ "]";
	}
	
	

}
