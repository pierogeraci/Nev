
package it.softstrategy.nevis.configuration.init;

import java.util.concurrent.CountDownLatch;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.enums.NevisAlarm;
import it.softstrategy.nevis.exceptions.NevisLicenseException;
import it.softstrategy.nevis.exceptions.RecordingStorageConfigurationException;
import it.softstrategy.nevis.exceptions.RecordingStorageMountPoolException;


/**
 * @author lgalati
 *
 */
public class DebianATINevisInitializer extends NevisInitializer implements Runnable {
	
	private static final Logger LOG = LogManager.getLogger(DebianATINevisInitializer.class.getName());
	
	
//	private NevisConfiguration configuration;
	
	private final CountDownLatch startSignal;

	
	public DebianATINevisInitializer(CountDownLatch startSignal) {
		
		this.startSignal = startSignal;
		
//		configuration = new NevisConfigurationImpl();
		
//		this.recsStorageInitBehavior = new LUKSPartitionInitializer();
		this.recsStorageInitBehavior = new LUKSPartitionsPoolInitializer();
		
		this.workingFolderInitBehavior = new LFSWorkFolderInitializer();
		
		//REC_LIST.xml initialize is delegated to NevisMonitor
//		this.recordingsRegisterInitBehavior = new RecListSerializerInitializer();
		
		this.licenseManagerBehavior = new RSALicenseManager();
	}

	@Override
	public void run() {
		
			
		try {
			LOG.info("Checking License!");
			licenseManagerBehavior.checkLicense();
			LOG.info("License OK!");
			
			
			recsStorageInitBehavior.initRecordingsStorage();
			
			
			workingFolderInitBehavior.cleanWorkingFolder();
			
			//REC_LIST.xml initialize is delegated to NevisMonitor
//			recordingsRegisterInitBehavior.initRecordingsRegister();
			
			startSignal.countDown(); //Unblock other threads
			
		} catch (NevisLicenseException e) {
			LOG.fatal(NevisAlarm.LICENSE.toString() + " - 1 - License Check Error", e);
		} catch (RecordingStorageConfigurationException e) {
			LOG.fatal(NevisAlarm.DISKS_CONFIGURATION.toString() + " - 1 - Disk Configuration Error", e);
		} catch (RecordingStorageMountPoolException e) {
			LOG.fatal(NevisAlarm.ARCHIVE.toString() + " - 1 - Disk Pool Setup Error", e);
		} catch (Exception e) {
			LOG.error("Error during initialization phase", e);
		} 

	}

}
