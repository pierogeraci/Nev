package it.softstrategy.nevis;

import java.io.BufferedInputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;

public class SignFile {

	public static void main(String[] args) {
		String dataFileToSign = "nevis.lic";
		String sigfilename = "nevis.sig";
		String privateKey = "private.sig.key";
		String publicKey = "public.sig.key";

		try {	
			if (args[0].equals("-s")) {
				/* Generate a DSA signature */
				dataFileToSign=args[1];
				sigfilename=args[2];
				privateKey=args[3];
				ObjectInputStream keyIn = new ObjectInputStream(new FileInputStream(privateKey));
				PrivateKey privKey = (PrivateKey) keyIn.readObject();
				keyIn.close();
			
				/* Create a Signature object and initialize it with the private key */
				Signature sig = Signature.getInstance("SHA1withRSA");
				sig.initSign(privKey);

				/* Update and sign the data */
	
				FileInputStream fis = new FileInputStream(dataFileToSign);
				BufferedInputStream bufin = new BufferedInputStream(fis);
				byte[] buffer = new byte[1024];
				int len;
				while (bufin.available() != 0) {
					len = bufin.read(buffer);
					sig.update(buffer, 0, len);
				}
	
				bufin.close();

				/* Save the signature in a file */
				writeBytesToLocalFile(sig.sign(),sigfilename);
				System.out.println("The signature of " + dataFileToSign + " is in the file " + sigfilename);
			}
			else {
				dataFileToSign=args[1];
				sigfilename=args[2];
				publicKey=args[3];				
				File f=new File (publicKey); 
				int filesize = (int) f.length(); 
				byte[] publicKeyData = new byte[filesize]; 		
				DataInputStream in = new DataInputStream(new FileInputStream(f)); 
				in.readFully(publicKeyData); 
				in.close();
				
				File originalDataFile=new File (dataFileToSign); 
				int originalDataFilesize = (int) originalDataFile.length(); 
				byte [] originalData = new byte[originalDataFilesize]; 
				DataInputStream originalDataIn = new DataInputStream(new FileInputStream(originalDataFile)); 
				originalDataIn.readFully(originalData); 
				originalDataIn.close(); 
				
				ObjectInputStream keyIn = new ObjectInputStream(new FileInputStream(publicKey));
				PublicKey pubKey = (PublicKey) keyIn.readObject();
				keyIn.close();
				
				Signature sig = Signature.getInstance ("SHA1withRSA");
				sig.initVerify(pubKey);
				sig.update(originalData); 
				
				File signedDataFile=new File (sigfilename); 
				int signedDataFilesize = (int) signedDataFile.length(); 
				byte[] signedData = new byte[signedDataFilesize]; 
				DataInputStream signeddataIn = new DataInputStream(new FileInputStream(signedDataFile)); 
				signeddataIn.readFully(signedData); 
				signeddataIn.close(); 
				
				boolean isSignOk = sig.verify (signedData); 
				System.out.println ("Signature verification results are: " + isSignOk);
			}
		} 
		catch (Exception e) {
			e.printStackTrace();
			System.err.println("Caught exception " + e.toString());
		}
	}
	
	public static byte[] getBytesFromLocalFile(String filename) {
		try {
			FileInputStream keyfis = new FileInputStream(filename);
			byte[] encKey = new byte[keyfis.available()];
			keyfis.read(encKey);
			keyfis.close();
			return encKey;
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public static void writeBytesToLocalFile(byte[] bytes, String filename) {
		try {

			FileOutputStream sigfos = new FileOutputStream(filename);
			sigfos.write(bytes);

			sigfos.close();
		} catch (IOException ioe) {
			ioe.printStackTrace();
		}
	}
}