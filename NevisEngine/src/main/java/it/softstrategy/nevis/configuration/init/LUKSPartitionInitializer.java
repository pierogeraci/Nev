package it.softstrategy.nevis.configuration.init;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.security.MessageDigest;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.zeroturnaround.exec.ProcessExecutor;
import org.zeroturnaround.exec.ProcessResult;

import it.softstrategy.nevis.exceptions.RecordingStorageMountPoolException;

/**
 * @author lgalati
 *
 *
 *	DEPRECATED
 */
public class LUKSPartitionInitializer implements RecordingsStorageInitBehavior {
	
	private static final Logger LOG = LogManager.getLogger(LUKSPartitionInitializer.class.getName());

	
	@Override
	public void initRecordingsStorage() throws RecordingStorageMountPoolException {

		//Check for the presence of the crypted partition
		try {
			ProcessResult pr = new ProcessExecutor("/bin/bash", "-c", "lsblk | grep -E videocrypt\\|nevis").readOutput(true).execute();
			if ( pr.outputUTF8().equals("") ) {
				String userToken = getUserToken();

				//Opening LUKS Crypted Partition
				LOG.debug("Opening crypted partition");
				String cmd;


				cmd = "echo -n \'" + userToken + "\' | cryptsetup luksOpen /dev/sda3 videocrypt";
				ProcessResult pr2 = new ProcessExecutor("/bin/bash", "-c", cmd).readOutput(true).execute();

				if (pr2.getExitValue() != 0) {
					throw new Exception("Error while opening Crypted Partition: " + pr2.outputUTF8());
				}

				//Mount LUKS partition
				LOG.debug("Mounting crypted partition");
				ProcessResult pr3 = new ProcessExecutor("/bin/bash", "-c", "mount /dev/mapper/videocrypt /nevis").readOutput(true).execute();
				if (pr3.getExitValue() != 0) {
					throw new Exception("Error while mounting Crypted Partition: " + pr3.outputUTF8());
				}

			} else {
				LOG.debug("Crypted Partition already mounted " /*+ pr.outputUTF8()*/ );
			}
		}
		catch (Exception e) {
			throw new RecordingStorageMountPoolException("Unexpected Exception while setting up recording storage", e);
		}

	}
	
	/** Utility Methods */
	private String getUserToken() throws IOException {
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
//      LOG.debug("passHash: " + passHash );
        String retKeyFinal;
		retKeyFinal = encryptKey(encryptKey(passHash,"SHA-512"),"SHA-512");
//		LOG.debug("retKeyFinal: " + retKeyFinal );
        return retKeyFinal;
    }
	
	private String encryptKey(String input, String sha) {
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
	
	//TODO: move in an utility class
//	private boolean isDebianOS() throws Exception {
//		ProcessResult pr = new ProcessExecutor("/bin/bash", "-c", "cat /etc/issue").readOutput(Boolean.TRUE).execute();
//		
//		return pr.outputUTF8().toUpperCase().contains("DEBIAN");
//		
//	}

}
