/**
 * 
 */
package it.softstrategy.nevis.events;

import java.util.List;

import it.softstrategy.nevis.model.NevisCamera;

/**
 * @author lgalati
 *
 */
public class OnvifDiscoveryEvent {
	
	
	private List<NevisCamera> cameras;

	
	public OnvifDiscoveryEvent(List<NevisCamera> cameras) {
		this.cameras = cameras;
	}

	
	public List<NevisCamera> getCameras() {
		return cameras;
	}
	
	
	

}
