package it.softstrategy.nevis.exceptions;

/**
 * @author lgalati
 *
 */
public class NevisLicenseException extends Exception {

	
	private static final long serialVersionUID = 1L;

		public NevisLicenseException(String message, Throwable cause, boolean enableSuppression,
			boolean writableStackTrace) {
		super(message, cause, enableSuppression, writableStackTrace);
		
	}

	public NevisLicenseException(String message, Throwable cause) {
		super(message, cause);
		
	}

	public NevisLicenseException(String message) {
		super(message);
		
	}

	public NevisLicenseException(Throwable cause) {
		super(cause);
		
	}

	
	
}
