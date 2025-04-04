
package it.softstrategy.nevis.configuration.init;

import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.nio.file.Files;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.exceptions.NevisLicenseException;
import it.softstrategy.nevis.slot.SlotsManagerSingleton;
import it.softstrategy.nevis.util.IPUtil;
import it.softstrategy.nevis.util.MacAddressUtil;

/**
 * @author lgalati
 *
 */
public class RSALicenseManager implements LicenseManagerBehavior {

	private static final Logger LOG = LogManager.getLogger(RSALicenseManager.class.getName());
	
	
	//TODO: obfuscate this AES_KEY
	private static final String AES_KEY = "jlkuL65kovCt0F5g38Oo7a1CZ5CCg2P2LpRHp8SB7eE=";
	private static final String SEPARATOR = "\\|";
	
	private final NevisConfiguration configuration;
	
	
	public RSALicenseManager() {
		configuration = new NevisConfigurationImpl();
	}


	@Override
	public void checkLicense() throws NevisLicenseException  {
		
		
		boolean test = false;
		if (test) {
			LOG.info("Controllo licenza disabilitata");
			SlotsManagerSingleton.getInstance().setMaxActiveSlots(40);
			return;
		}
		
		int licensesNumber = 0;
		String name = "";
		String serialNumber = "";
		Date expireDate = null;
		
		
		try {
			
			//Previously the file name was private.rsa.encrypted
			String rsaSecretKeyFilePath = configuration.getLicenseFolder() + File.separator + "6705a1ced7b64e57649095378a2ecf7c";
			//Previously the file name was nevis.license
			String licenseFilePath = configuration.getLicenseFolder() + File.separator + "a96ba95557c4538ce147858c7b60ec07";
			//STEP1 - Decritto la chiave RSA privata nevis
			SecretKey secretKey = getSecretKey();
			Cipher cipher = Cipher.getInstance("AES");
			cipher.init(Cipher.DECRYPT_MODE, secretKey);

			// Carico la chiave private RSA criptata da file
			byte[] encryptedBytes = Files.readAllBytes(new File(rsaSecretKeyFilePath).toPath());
//			LOG.debug("encryptedBytes : " + encryptedBytes.length);
			//La decripto
			byte[] plainBytes = cipher.doFinal(encryptedBytes);
//			LOG.debug("plainBytes : " + plainBytes.length);
			//E creo l'oggetto Private Key
			PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(plainBytes);
			KeyFactory fact = KeyFactory.getInstance("RSA");
			PrivateKey privateKey = fact.generatePrivate(keySpec);
//			LOG.debug("private key loaded");

			//decripta la licenza con la chiave privata e leggi il MAC Address e Il numero di licenze concesse

			byte[] licenseEncryptedByes = Files.readAllBytes(new File(licenseFilePath).toPath());


			/*Cipher*/ cipher = Cipher.getInstance("RSA/ECB/PKCS1PADDING");
			cipher.init(Cipher.DECRYPT_MODE, privateKey);
			byte[] licenseDecryptedBytes = cipher.doFinal(licenseEncryptedByes);

			StringBuilder sb = new StringBuilder();

			for (byte b: licenseDecryptedBytes) {
				if (b != 0) sb.append ((char) b);
			}
			String licenseDecryptedContent = sb.toString();
//			LOG.debug(licenseDecryptedContent);

			String[] contentArray = licenseDecryptedContent.split(SEPARATOR);
			licensesNumber = Integer.parseInt(contentArray[0]);
			name = contentArray[1];
			serialNumber = contentArray[2];
			long timestamp = Long.parseLong(contentArray[3]);
			expireDate = new Date(timestamp);

//			LOG.debug(licensesNumber);
//			LOG.debug(name);
//			LOG.debug(serialNumber);
//			LOG.debug(expireDate);
			
//			InetAddress ip = IPUtil.getMyInetAddress();
//			String localMacAddress = MacAddressUtil.getByInetAddress(ip);
			
			List<String> addresses = MacAddressUtil.getHardwareAddresses();

			Collections.sort(addresses, new Comparator<String>() {

				@Override
				public int compare(String o1, String o2) {
					
					return o1.compareTo(o2);
					
				}
			});
			
			String sn = String.join("", addresses).toUpperCase();

			if (expireDate == null || expireDate.compareTo(new Date()) < 0) {

				throw new NevisLicenseException("License Expired");
			} else if (serialNumber == null || serialNumber.isEmpty() || !serialNumber.equalsIgnoreCase(sn)) {

				throw new NevisLicenseException("License not valid");
			} else {
				//Leggi il numero di licenze richieste e caricalo nello slot manager singleton
				LOG.info("License valid.");
				SlotsManagerSingleton.getInstance().setMaxActiveSlots(licensesNumber);
			}

		} catch (IOException | NoSuchAlgorithmException | NoSuchPaddingException | InvalidKeyException | IllegalBlockSizeException | BadPaddingException | InvalidKeySpecException e) {
			throw new NevisLicenseException("Error while reading the license", e);
		}
		
	}
	
	private static SecretKey getSecretKey() {
		byte[] decodedKey = Base64.getDecoder().decode(AES_KEY);
        SecretKey secretKey = new SecretKeySpec(decodedKey, 0, decodedKey.length, "AES");
        return secretKey;
	}
	

}
