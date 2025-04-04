package it.softstrategy.nevis.util;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;

/**
 * @author lgalati
 *
 */
public class ShutdownHandler implements Runnable {

	private static final Logger LOG = LogManager.getLogger(ShutdownHandler.class.getName());
	
	
//	private final NevisConfiguration configuration;
// 
//	public ShutdownHandler() {
//		configuration = new NevisConfigurationImpl();
//	}


	@Override
	public void run() {

		LOG.info("Received Term Signal.");
		
		
		//N.B. The ZT-EXEC library manages the forwarding of the "termination signal"
		// to the Recording Processes
		
		
//		try {
//			RecListRestService service = new RecListRestService(configuration.getRecordingsDataSourceHost(), 
//					configuration.getRecordingsDataSourcePort());
//			service.addRecordings(new ArrayList<>());
//			LOG.info("Updated Recordings register");
//			
//			//Do we need to stop all the current threads?
//		} catch (IOException e) {
//			LOG.error("Unexpected IOException while updating REC_LIST.xml", e);
//		}
	}

}
