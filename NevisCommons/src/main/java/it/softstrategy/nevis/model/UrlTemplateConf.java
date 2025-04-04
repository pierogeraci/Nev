package it.softstrategy.nevis.model;

import java.util.ArrayList;
import java.util.List;

import org.simpleframework.xml.ElementList;
import org.simpleframework.xml.Root;

@Root(name="nevis")
public class UrlTemplateConf {

	@ElementList(inline=true)
	private List<UrlTemplateCamera> cameras;

	
	public List<UrlTemplateCamera> getCameras() {
		return cameras;
	}


	public void setCameras(List<UrlTemplateCamera> cameras) {
		this.cameras = cameras;
	}
	
	public String getUrlTemplate(String cameraModel, String cameraVendor, String idProfile) {
		String ret = null;
		
		for(UrlTemplateCamera camera : cameras) {
			if(camera.getVendor().equals(cameraVendor) && camera.getModel().equals(cameraModel)) {
				for (UrlTemplateCameraProfile profile : camera.getProfiles()) {
					if (profile.getId().equals(idProfile)) {
						ret = profile.getUrlTemplate();
						break;
					}
				}
				break;
			}
		}
		
		return ret;
	}
	
	public UrlTemplateCameraProfile getUrlTemplateCameraProfile(String cameraModel, String cameraVendor, Integer sensorId, String idProfile) {
		
		for(UrlTemplateCamera camera : cameras) {
			if(camera.getVendor().equals(cameraVendor) && camera.getModel().equals(cameraModel) && camera.getSensorId().equals(sensorId)) {
				for (UrlTemplateCameraProfile profile : camera.getProfiles()) {
					if (profile.getId().equals(idProfile)) {
						return profile;
					}
				}
				
			}
		}
		
		return null;
	}
	
	public String getUrlTemplateCameraId(String cameraModel, String cameraVendor, Integer sensorId) {
		for(UrlTemplateCamera camera : cameras) {
			if(camera.getVendor().equals(cameraVendor) && camera.getModel().equals(cameraModel) && camera.getSensorId().equals(sensorId)) {
				return camera.getId();
			}
		}
		
		return null;
	}
	
	public List<UrlTemplateCamera> getUrlTemplateCameras(String cameraModel, String cameraVendor){
		List<UrlTemplateCamera> urlTemplateCameras = new ArrayList<>();
		for(UrlTemplateCamera camera : cameras) {
			if(camera.getVendor().equals(cameraVendor) && camera.getModel().equals(cameraModel)) {
				urlTemplateCameras.add(camera);
			}
		}		
		return urlTemplateCameras;
	}

	@Override
	public String toString() {
		return "UrlTemplateConf [cameras = " + cameras + "]";
	}
}
