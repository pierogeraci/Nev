package it.softstrategy.nevis.model;

import org.simpleframework.xml.Element;
import org.simpleframework.xml.Root;

@Root(name="profile")
public class UrlTemplateCameraProfile {

	@Element
	private String id;
	
	@Element(name="framerate")
	private int frameRate;
	
	@Element
	private String resolution;
	
	@Element(name="url_template", data=true)
	private String urlTemplate;

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	public int getFrameRate() {
		return frameRate;
	}

	public void setFrameRate(int frameRate) {
		this.frameRate = frameRate;
	}

	public String getResolution() {
		return resolution;
	}

	public void setResolution(String resolution) {
		this.resolution = resolution;
	}

	public String getUrlTemplate() {
		return urlTemplate;
	}

	public void setUrlTemplate(String urlTemplate) {
		this.urlTemplate = urlTemplate;
	}

	@Override
	public String toString() {
		return "UrlTemplateCameraProfile ["
				+ "id " + id 
				+ ", frameRate " + frameRate 
				+ ", resolution " + resolution
				+ ", urlTemplate " + urlTemplate 
				+ "]";
	}
	
	
}
