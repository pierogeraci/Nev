/**
 * 
 */
package it.softstrategy.nevis.configuration.init;

import java.util.ArrayList;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.rest.RecListRestService;

/**
 * @author lgalati
 *
 */
public class RecListSerializerInitializer implements RecordingsRegisterInitBehavior {

	private static final Logger LOG = LogManager.getLogger(RecListSerializerInitializer.class.getName());
	
	private final NevisConfiguration configuration;
	
	public RecListSerializerInitializer() {
		configuration = new NevisConfigurationImpl();
	}

	@Override
	public void initRecordingsRegister() throws Exception {

		LOG.debug("Resetting the Serializer of REC_LIST.xml");
		//Svuoto il Serializzatore e il file REC_LIST.xml
		RecListRestService service = new RecListRestService(configuration.getRecordingsDataSourceHost(), 
															 configuration.getRecordingsDataSourcePort());
		service.addRecordings(new ArrayList<>());
		
		 
	}

}
