/**
 * 
 */
package it.softstrategy.nevis.onvif;


import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.simpleframework.xml.Serializer;
import org.simpleframework.xml.core.Persister;

import it.softstrategy.nevis.AppHelper;
import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.events.OnvifDiscoveryEvent;
import it.softstrategy.nevis.model.NevisCamera;
import it.softstrategy.nevis.model.NevisCameraList;

/**
 * @author lgalati
 *
 *	DEPRECATO
 */
public class OnvifDiscoveryManager implements OnvifDiscoveryListener/*, Runnable*/ {
	
	private static final Logger LOG = LogManager.getLogger(OnvifDiscoveryManager.class.getName());
	
	
	private final NevisConfiguration configuration;
	
	//Contiene la lista delle telecamere correnti
	private List<NevisCamera> cameras;

	private OnvifDeviceBrowser onvifBrowser;

	
	
	// this is the object we will be synchronizing on ("the monitor")
//    private final Object MONITOR = new Object();

	public OnvifDiscoveryManager() {		
		configuration = new NevisConfigurationImpl();
		
		cameras = new ArrayList<>();
	}
	
	public void start() {
		if (onvifBrowser == null) {
//			Integer attempts = configuration.getOnvifDiscoveryMaxTries();
			Long period = configuration.getOnvifDiscoveryPeriod();
			Integer timeout = configuration.getOnvifDiscoverySocketTimeout();
			onvifBrowser = new OnvifDeviceBrowser(/*attempts,*/ period, timeout);
			onvifBrowser.addOnvifDiscoveryListener(this);
			
			if (period <= 0) {
				LOG.debug("Single Mode");
				onvifBrowser.startSingleDiscovery();
			} else {
				LOG.debug("Repeteable Mode");
				onvifBrowser.startDiscovery();
			}
		}
		
	}
	
	public void stop() {
		if (onvifBrowser != null) {
			onvifBrowser.stopDiscovery();
			onvifBrowser.removeOnvifDiscoveryListener(this);
			onvifBrowser = null; //Sicuro?
		}
	}



	@Override
	public void handleOnvifDiscoveryResult(List<NevisCamera> discoveredCameras) {
		LOG.trace("Handling Onvif Discovery Result");

		boolean camerasChanged = false;
		for (NevisCamera discoveredCam : discoveredCameras) {				
			if (cameras.contains(discoveredCam)) {
				updateCameraLastSeen(cameras.get(cameras.indexOf(discoveredCam)), discoveredCam);
			} else {
				camerasChanged = cameras.add(discoveredCam);
			}
		}

		updateCameraFile();
		
		if (camerasChanged) {
			sendNotification();
		}
	}
	
	
	private void sendNotification() {
		LOG.debug("Found New Cameras... " + cameras.toString());
		OnvifDiscoveryEvent event = new OnvifDiscoveryEvent(new ArrayList<>(cameras));
		AppHelper.getInstance().getEventBus().post(event);		
	}
	
	private void updateCameraFile() {
		NevisCameraList camerasList = new NevisCameraList();
		camerasList.setCameras(cameras);
		Serializer serializer = new Persister();
		String fileOutputPath = configuration.getOnvifDiscoveryStorageFilePath();// NevisMain.SERVICE_FOLDER + File.separator +  properties.getProperty("DISCOVERY_NETWORK_LIST_CAMS_PATH");
		File fileOutput = new File(fileOutputPath);
		try {
			serializer.write(camerasList, fileOutput);
		} catch (Exception e) {
			LOG.error("Can't write discovered cameras list on file " + fileOutputPath, e);
		}
	}
	
	
	private void updateCameraLastSeen(NevisCamera currentVersion, NevisCamera lastVersion) {
		currentVersion.setLastSeen(lastVersion.getLastSeen());
	}
		

}
