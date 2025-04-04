/**
 * 
 */
package it.softstrategy.nevis.configuration.camera;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.io.FilenameUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.simpleframework.xml.Serializer;
import org.simpleframework.xml.core.Persister;

import it.softstrategy.nevis.AppHelper;
import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.events.ManualCameraEvent;
import it.softstrategy.nevis.externalconf.FileWatcher;
import it.softstrategy.nevis.util.FileWatcherListener;
import it.softstrategy.nevis.model.NevisCamera;
import it.softstrategy.nevis.model.NevisCameraList;

/**
 * @author lgalati
 *
 */
public class ManualCameraConfigurationManager implements FileWatcherListener {

	private final static Logger LOG = LogManager.getLogger(ManualCameraConfigurationManager.class.getName());
	
	
	private final NevisConfiguration configuration;
	
	
	private Thread thread;
	private FileWatcher fileWatcher;
	
	
	private boolean watch;
	
	
	
	public ManualCameraConfigurationManager(boolean watch) {
		this.watch = watch;
		this.configuration = new NevisConfigurationImpl();
	}
	
	public void start() {
		LOG.debug("start");
		
		fileChanged();
		
		if (watch) {
			
			if (fileWatcher != null) {
				fileWatcher.removeFileWatcherListener(this);
			}
			//Avvio/Riavvio
			String folderPath = FilenameUtils.getFullPath(configuration.getManualCamsFilePath());
			String fileName = configuration.getManualCamsFilePath();
			fileWatcher = new FileWatcher(folderPath, fileName);
			fileWatcher.addFileWatcherListener(this);
			thread = new Thread(fileWatcher);
			thread.setName("File " + fileName + " Watcher");
			thread.start();
		}
		
	}
	
	public void stop() {
		
		if (thread != null) {
			thread.interrupt();
		}
		
	}



	@Override
	public void fileChanged() {
		LOG.debug("file changed");
		Serializer serializer = new Persister();
		File source = new File(configuration.getManualCamsFilePath());
		
		List<NevisCamera> cameras = null;
		try {
			NevisCameraList cameraList = serializer.read(NevisCameraList.class, source);
			cameras = cameraList.getCameras();
		} catch (Exception e) {
			LOG.error("Can't read manual camera infos from file " + configuration.getManualCamsFilePath(), e);
			cameras = new ArrayList<>();
		}
		
		ManualCameraEvent event = new ManualCameraEvent(cameras);
		
		AppHelper.getInstance().getEventBus().post(event);
		
	}

}
