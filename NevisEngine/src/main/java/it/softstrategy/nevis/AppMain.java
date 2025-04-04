package it.softstrategy.nevis;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.configuration.init.DebianATINevisInitializer;
import it.softstrategy.nevis.configuration.init.NevisInitializer;
import it.softstrategy.nevis.externalconf.NevisRecordingsConfigurationManager;
import it.softstrategy.nevis.recording.RecordingProcessManager;
import it.softstrategy.nevis.util.ShutdownHandler;

public class AppMain {
	
	private static final Logger LOG = LogManager.getLogger(AppMain.class.getName());

	public static void main(String[] args) {
		
		LOG.info("NEVIS ENGINE - Starting setup phase...");



		Runtime.getRuntime().addShutdownHook(new Thread(new ShutdownHandler()));
		
		final CountDownLatch startSignal = new CountDownLatch(1);

		//Init 	
		NevisInitializer initializer = new DebianATINevisInitializer(startSignal);
		Thread initThread = new Thread(initializer);
		initThread.start();

		
		try {
			startSignal.await();
		} catch (InterruptedException e) {
			LOG.error("Unexpected InterruptedException", e);
		}
		
		
		
		//----------------------- MODE 1 --------------- QUELLO TRENITALIA/ALMAVIVA	
		
		RecordingProcessManager processManager = new RecordingProcessManager();
		processManager.initialize();
		
		NevisRecordingsConfigurationManager confManager = new NevisRecordingsConfigurationManager();
		confManager.start(false);
		//-------------------------------------------------------------------------------
		
		
		
		//---------------------- MODE 2 -------------------------------------------------------
		
//		RecordingProcessManager processManager = new RecordingProcessManager();
//		processManager.initialize();
//		
//		NevisCameraManager ncm = new NevisCameraManager();
//		ncm.initialize();
//		
//		LoadBalancer loadBalancer = new LoadBalancer();
//		loadBalancer.initialize();
//		
//		ManualCameraConfigurationManager mccm = new ManualCameraConfigurationManager(false);
//		mccm.start();
//		
//		NVRDiscoveryManager ndm = new NVRDiscoveryManager();
//		ndm.start();
//		
//		OnvifDiscoveryManager odm = new OnvifDiscoveryManager();
//		odm.start();		
		//--------------------------------------------------------------------------------------
		
		
		
		
		LOG.info("NEVIS ENGINE - Setup endend. Start working");
		
		
		while (true) {
			if (!confManager.isWorking()) {
				confManager.start(true);
			}
			
			try {
				TimeUnit.MILLISECONDS.sleep(500);
			} catch (InterruptedException e) {
				LOG.error("Unexpected InterruptedException.", e);
			}
		}
	}

}
