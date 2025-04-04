/**
 * 
 */
package it.softstrategy.nevis.events;

import java.util.List;

import it.softstrategy.nevis.discovery.NevisServiceDescription;

/**
 * @author lgalati
 *
 */
public class NVRDiscoveryEvent {
	
	
	private List<NevisServiceDescription> descriptors;

	
	public NVRDiscoveryEvent(List<NevisServiceDescription> descriptors) {
		this.descriptors = descriptors;
	}


	public List<NevisServiceDescription> getDescriptors() {
		return descriptors;
	}
	
	

}
