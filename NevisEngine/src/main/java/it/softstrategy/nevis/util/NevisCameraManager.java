
package it.softstrategy.nevis.util;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.simpleframework.xml.Serializer;
import org.simpleframework.xml.core.Persister;

import com.google.common.eventbus.Subscribe;

import it.softstrategy.nevis.AppHelper;
import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.events.ManualCameraEvent;
import it.softstrategy.nevis.events.OnvifDiscoveryEvent;
import it.softstrategy.nevis.events.VideoSourceEvent;
import it.softstrategy.nevis.model.NevisCamera;
import it.softstrategy.nevis.model.UrlTemplateCamera;
import it.softstrategy.nevis.model.UrlTemplateConf;

/**
 * @author lgalati
 *
 *
 */
public class NevisCameraManager {


	private final static Logger LOG = LogManager.getLogger(NevisCameraManager.class.getName());

	
	
	private final NevisConfiguration configuration;

	private List<NevisCamera> manualCameras;
	private List<NevisCamera> onvifCameras;
	
	
	
	public NevisCameraManager() {
		
		configuration = new NevisConfigurationImpl();
		
		manualCameras = null;
		onvifCameras = null;
	}
	
	public void initialize() {
		AppHelper.getInstance().getEventBus().register(this);
	}
	
	
	@Subscribe
	public synchronized void handleManualCameraEvent(ManualCameraEvent event) {
		LOG.debug("ricevute camere manuali");
		manualCameras = event.getCameras();
		
		sendNotification();
	}
	
	@Subscribe
	public synchronized void handleOnvifDiscoveryEvent(OnvifDiscoveryEvent event) {
		LOG.debug("ricevute camere onvif");
		onvifCameras = event.getCameras();
		
		sendNotification();
	}
	
	
	private void sendNotification() {
		//TODO qui potrei fare qualche check
		// ed eventualmente inviare degli allarmi
		
		if (manualCameras != null && onvifCameras != null) {
			List<NevisCamera> cameras = new ArrayList<>();
			cameras.addAll(manualCameras);
			cameras.addAll(onvifCameras);
			
			UrlTemplateConf conf = readConfFromDisk();
			
			List<NevisVideoSource> videoSources = new ArrayList<>();
			for(NevisCamera camera : cameras) {
				List<UrlTemplateCamera> temps = conf.getUrlTemplateCameras(camera.getModel(), camera.getVendor());
				for(UrlTemplateCamera tcam : temps) {				
					NevisVideoSource newVideoSource = new NevisVideoSource();
					newVideoSource.setId(tcam.getId());
					newVideoSource.setNevisCamera(camera);
					newVideoSource.setSensorId(tcam.getSensorId());
					newVideoSource.setTemplate(tcam);;
					videoSources.add(newVideoSource);
				}
			}
//			LOG.debug("Sorgenti video da bilanciare " + videoSources);
			VideoSourceEvent event = new VideoSourceEvent(videoSources);
			AppHelper.getInstance().getEventBus().post(event);
		}
		
	}


	
	private UrlTemplateConf readConfFromDisk() {
		Serializer serializer = new Persister();
		UrlTemplateConf conf = null;
		String urlTemplateFile = configuration.getUrlTemplateFilePath();
		LOG.debug("Reading url template configuration file " + urlTemplateFile);
		File source = new File(urlTemplateFile);
		try {
			conf = serializer.read(UrlTemplateConf.class, source);
		} catch (Exception e) {
			LOG.error("Can't read info on url templates for cameras from file " + urlTemplateFile, e);
			conf = new UrlTemplateConf();
			conf.setCameras(new ArrayList<>());
		}
		
		return conf;
	}



}
