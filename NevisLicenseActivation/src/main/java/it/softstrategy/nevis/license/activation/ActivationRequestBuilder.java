package it.softstrategy.nevis.license.activation;

import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.security.PublicKey;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;

import javax.crypto.Cipher;


import it.softstrategy.nevis.license.util.CryptoUtil;
import it.softstrategy.nevis.license.util.NetworkUtil;

public class ActivationRequestBuilder {
	
	private final String LICENSE_FOLDER = "/nevis_app/nevis_latest/license";
	private final String PUBLIC_KEY_FILENAME = "yxo3asjrv9xvfx2un88f1hpvmwlck84b"; 
	
	private String outputFileName;
	
			
	public ActivationRequestBuilder() {
		outputFileName = "activation.req";
	}


	public String getOutputFileName() {
		return outputFileName;
	}

	public void setOutputFileName(String outputFileName) {
			this.outputFileName = outputFileName;		
	}


	public void generateActivationRequest() throws Exception {
		
    	//1 - Estrarre i dati dalla macchina (MACADDRESS e Mother Board Id)
//    	String macAddress = NetworkUtil.getMacAddress();
		List<String> addresses = NetworkUtil.getHardwareAddresses();
		
		Collections.sort(addresses, new Comparator<String>() {

			@Override
			public int compare(String o1, String o2) {
				
				return o1.compareTo(o2);
				
			}
		});
		
		String sn = String.join("", addresses).toUpperCase();
    	
    	
    	//2 - Generazione contenuto file di richiesta attivazione
    	SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
    	String activationReq = sn + "|" + sdf.format(new Date());
    	
    	
		PublicKey publicKey = CryptoUtil.loadPublicKey(LICENSE_FOLDER + File.separator + PUBLIC_KEY_FILENAME);
		
		Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1PADDING");
		cipher.init(Cipher.ENCRYPT_MODE, publicKey);
		
//		crypt(serialNumber, out, cipher);
		byte[] encryptedData = cipher.doFinal(activationReq.getBytes());
		
		DataOutputStream out = new DataOutputStream(new FileOutputStream(LICENSE_FOLDER + File.separator + outputFileName));
		out.write(encryptedData);
		out.close();
		
		System.out.println("Generato file di richiesta attivazione : " + LICENSE_FOLDER  + File.separator + outputFileName);
	}

}
