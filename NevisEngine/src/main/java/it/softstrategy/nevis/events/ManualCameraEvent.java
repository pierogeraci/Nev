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
public class ManualCameraEvent {

	
	private List<NevisCamera> cameras;

	
	public ManualCameraEvent(List<NevisCamera> cameras) {
		this.cameras = cameras;
	}


	public List<NevisCamera> getCameras() {
		return cameras;
	}
	
	
	
	
}
