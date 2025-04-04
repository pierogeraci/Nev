/**
 * 
 */
package it.softstrategy.nevis.configuration.init;

import it.softstrategy.nevis.exceptions.NevisLicenseException;

/**
 * @author lgalati
 *
 */
public interface LicenseManagerBehavior {
	
	void checkLicense() throws NevisLicenseException;

}
