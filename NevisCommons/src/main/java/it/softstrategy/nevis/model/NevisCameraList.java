package it.softstrategy.nevis.model;

import java.util.List;

import org.simpleframework.xml.ElementList;
import org.simpleframework.xml.Root;

@Root(name="nevis-cameras")
public class NevisCameraList {
	
	@ElementList(inline=true)
	private List<NevisCamera> cameras;

	public List<NevisCamera> getCameras() {
		return cameras;
	}

	public void setCameras(List<NevisCamera> cameras) {
		this.cameras = cameras;
	}
	
	

}
