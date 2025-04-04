package it.softstrategy.nevis.onvif;

import java.util.List;

import it.softstrategy.nevis.model.NevisCamera;

/**
 * @author lgalati
 *
 */
public interface OnvifDiscoveryListener {
	
	void handleOnvifDiscoveryResult(List<NevisCamera> discoveredCameras);
//	void handleOnvifDiscoveryResult(NevisCamera discoveredCameras);

}
