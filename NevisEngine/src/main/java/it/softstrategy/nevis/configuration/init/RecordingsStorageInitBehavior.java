package it.softstrategy.nevis.configuration.init;

import it.softstrategy.nevis.exceptions.RecordingStorageConfigurationException;
import it.softstrategy.nevis.exceptions.RecordingStorageMountPoolException;

/**
 * @author lgalati
 *
 */
public interface RecordingsStorageInitBehavior {
	
	void initRecordingsStorage() throws RecordingStorageConfigurationException, RecordingStorageMountPoolException;

}
