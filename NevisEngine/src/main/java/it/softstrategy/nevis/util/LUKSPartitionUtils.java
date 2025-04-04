package it.softstrategy.nevis.util;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.security.MessageDigest;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * @author lgalati
 *
 */
public class LUKSPartitionUtils {

	private static final Logger LOG = LogManager.getLogger(LUKSPartitionUtils.class.getName());
	
	
	public static String getUserToken() throws IOException {

		String passHash = "";
		BufferedReader in = new BufferedReader(new FileReader("/etc/shadow"));
		//Leggo solo la prima riga del file
		String str = in.readLine();
		String[] arr = str.split(":");
		if (arr != null && arr.length > 1) {
			passHash = arr[1];
		}
		//p = ar[1].substring(ar[1].indexOf("$6$") + 3, ar[1].length() - 1);
		in.close();
		LOG.trace("passHash: " + passHash );
		String retKeyFinal;
		retKeyFinal = encryptKey(encryptKey(passHash,"SHA-512"),"SHA-512");
		LOG.trace("retKeyFinal: " + retKeyFinal );
		return retKeyFinal;
	}
	
	
	public static String encryptKey(String input, String sha) {
	    try {
	        MessageDigest md1 = MessageDigest.getInstance(sha);
	        md1.update(input.getBytes());

	        byte byteData[] = md1.digest();
	        StringBuffer hexString = new StringBuffer();
	        for (int i = 0; i < byteData.length; i++) {
	            String hex = Integer.toHexString(0xff & byteData[i]);
	            if (hex.length() == 1) hexString.append('0');
	            hexString.append(hex);
	        }
	        return hexString.toString();
	    } catch (Exception ex) {
	        LOG.error("Error while computing SHA", ex);
	        return "";
	    }
	}
}
