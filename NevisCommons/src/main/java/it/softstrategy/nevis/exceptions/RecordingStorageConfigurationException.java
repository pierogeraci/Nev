package it.softstrategy.nevis.exceptions;

/**
 * @author lgalati
 *
 */
public class RecordingStorageConfigurationException extends Exception {


	private static final long serialVersionUID = 1L;

	
	public RecordingStorageConfigurationException() {  }

	public RecordingStorageConfigurationException(String message, Throwable cause, boolean enableSuppression,
			boolean writableStackTrace) {
		super(message, cause, enableSuppression, writableStackTrace);
	}
	

	public RecordingStorageConfigurationException(String message, Throwable cause) {
		super(message, cause);
	}
	

	public RecordingStorageConfigurationException(String message) {
		super(message);
	}
	

	public RecordingStorageConfigurationException(Throwable cause) {
		super(cause);
	}
	
	
}
