package it.softstrategy.nevis;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.security.GeneralSecurityException;
import java.security.Key;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.SecureRandom;
import java.util.Scanner;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;

public class Manager {
	private static final int KEYSIZE = 2048;
	
	public static void main(String[] args) {
		try {
			if (args[0].equals("-genkey")) {
				KeyPairGenerator pairgen = KeyPairGenerator.getInstance("RSA");
				SecureRandom random = new SecureRandom();
				pairgen.initialize(KEYSIZE, random);
				KeyPair keyPair = pairgen.generateKeyPair();			
				
				//Genero pubblica
				ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream(args[1])); //File chiave pubblica
				out.writeObject(keyPair.getPublic());
				out.close();
				
				//Genero privata
				out = new ObjectOutputStream(new FileOutputStream(args[2])); //File chiave privata
				out.writeObject(keyPair.getPrivate());
				out.close();
			} 
			else if (args[0].equals("-sn")) {		
				Scanner scanner = new Scanner(System.in);
				System.out.print("Numero di telecamere: ");
				String numCams = scanner.nextLine();
				System.out.print("Societa: ");
				String societa = scanner.nextLine();				
				scanner.close();
				String serialNumber=getSerialNumber(numCams,societa);
				System.out.println(serialNumber);
			}
			else if (args[0].equals("-encrypt")) {
				String serialNumber=args[1];
				KeyGenerator keygen = KeyGenerator.getInstance("AES");
				SecureRandom random = new SecureRandom();
				keygen.init(random);
				SecretKey key = keygen.generateKey();
	
				// wrap with RSA public key
				ObjectInputStream keyIn = new ObjectInputStream(new FileInputStream(args[3]));
	            Key publicKey = (Key) keyIn.readObject();
	            keyIn.close();  				
	
				Cipher cipher = Cipher.getInstance("RSA");
				cipher.init(Cipher.WRAP_MODE, publicKey);
				byte[] wrappedKey = cipher.wrap(key);
				DataOutputStream out = new DataOutputStream(new FileOutputStream(args[2]));
				out.writeInt(wrappedKey.length);
				out.write(wrappedKey);
	
				cipher = Cipher.getInstance("AES");
				cipher.init(Cipher.ENCRYPT_MODE, key);
				crypt(serialNumber, out, cipher);
				out.close();
			} else {
				DataInputStream in = new DataInputStream(new FileInputStream(args[1]));
				int length = in.readInt();
				byte[] wrappedKey = new byte[length];
				in.read(wrappedKey, 0, length);
				
				// unwrap with RSA private key
				ObjectInputStream keyIn = new ObjectInputStream(new FileInputStream(args[2]));
				Key privateKey = (Key) keyIn.readObject();
				keyIn.close();
	
				Cipher cipher = Cipher.getInstance("RSA");
				cipher.init(Cipher.UNWRAP_MODE, privateKey);
				Key key = cipher.unwrap(wrappedKey, "AES", Cipher.SECRET_KEY);
				cipher = Cipher.getInstance("AES");
				cipher.init(Cipher.DECRYPT_MODE, key);
				String serialNumber=decrypt(in,cipher);
				System.out.println(serialNumber);
				in.close();
			}
		} catch (IOException e) {
			e.printStackTrace();
		} catch (GeneralSecurityException e) {
			e.printStackTrace();
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}			
	}
	
	public static void crypt(String in, OutputStream out, Cipher cipher)
			throws IOException, GeneralSecurityException {
		int blockSize = cipher.getBlockSize();
		int outputSize = cipher.getOutputSize(blockSize);
		byte[] outBytes = new byte[outputSize];

		int inLength = in.length();
		byte[] inBytes=StringToByteArray(in);
		if (inLength > 0)
			outBytes = cipher.doFinal(inBytes, 0, inLength);
		else
			outBytes = cipher.doFinal();
		out.write(outBytes);
	}

	public static String decrypt(InputStream in, Cipher cipher) throws IOException, GeneralSecurityException {
		int blockSize = cipher.getBlockSize();
		int outputSize = cipher.getOutputSize(blockSize);
		byte[] inBytes = new byte[blockSize];
		byte[] outBytes = new byte[outputSize];
		StringBuilder sb = new StringBuilder ();
		
		int inLength = 0;
	    boolean more = true;
	    while (more) {
	    	inLength = in.read(inBytes);
	    	if (inLength == blockSize) {
	    		int outLength = cipher.update(inBytes, 0, blockSize, outBytes);
	    	    for (byte b: outBytes) {
	    	    	if (b!=0) sb.append ((char) b);
	    	    }
	    	} 
	    	else more = false;
	    }
	    if (inLength > 0) 
	    	outBytes = cipher.doFinal(inBytes, 0, inLength);
	    else 
	    	outBytes = cipher.doFinal();
	    for (byte b: outBytes)
	    	if (b!=0) sb.append ((char) b);
	    return sb.toString ();
	}	
	
	private static byte[] StringToByteArray(String value) {
		byte[] buffer = new byte[value.length()];
		for(int i = 0; i < buffer.length; i++) {
			buffer[i] = (byte)value.charAt(i);
		}
		return buffer;
	}
	
	private static String getMacAddress() {
		String address="";
		try {
			InetAddress ip = InetAddress.getLocalHost();
	        NetworkInterface network = NetworkInterface.getByInetAddress(ip);
	        byte[] mac = network.getHardwareAddress();
	        StringBuilder sb = new StringBuilder();
	        for (int i = 0; i < mac.length; i++) {
	            //sb.append(String.format("%02X%s", mac[i], (i < mac.length - 1) ? "-" : ""));
	        	sb.append(String.format("%02X%s", mac[i], (i < mac.length - 1) ? "" : ""));
	        }
	        address=sb.toString();
		} catch (Exception ex){
			
		}
		return address;
	}
	
	private static String getSerialNumber(String numCams, String societa) {
		String serialNumber="";
		//serialNumber+=System.getProperties().getProperty("os.arch");
		//serialNumber+=System.getProperties().getProperty("os.name");
		//serialNumber+=System.getProperties().getProperty("os.version");
		serialNumber+=numCams+"|";
		serialNumber+=societa+"|";
		//serialNumber+=System.getProperties().getProperty("sun.arch.data.model");
		//serialNumber+=System.getenv().get("PROCESSOR_REVISION");
		//serialNumber+=System.getenv().get("PROCESSOR_LEVEL");
		//serialNumber+=System.getenv().get("NUMBER_OF_PROCESSORS");
		//serialNumber+=System.getProperties().getProperty("sun.cpu.isalist");
		serialNumber+=getMacAddress();
		//System.out.println(serialNumber);
		//return MD5(serialNumber);
		return serialNumber;
	}	
	
//	private static String MD5(String text){
//		MessageDigest md;
//		String md5="";
//		try{
//			md = MessageDigest.getInstance("MD5");
//			byte[] md5hash = new byte[32];
//			md.update(text.getBytes("iso-8859-1"), 0, text.length());
//			md5hash = md.digest();
//			md5=convertToHex(md5hash).toUpperCase();
//		}
//		catch (Exception ex){
//			ex.printStackTrace();
//		}
//		return md5;	
//	}
	
	private static String convertToHex(byte[] data) {
        StringBuffer buf = new StringBuffer();
        for (int i = 0; i < data.length; i++) {
        	int halfbyte = (data[i] >>> 4) & 0x0F;
        	int two_halfs = 0;
        	do {
	        	if ((0 <= halfbyte) && (halfbyte <= 9))
	                buf.append((char) ('0' + halfbyte));
	            else
	            	buf.append((char) ('A' + (halfbyte - 10)));
	        	halfbyte = data[i] & 0x0F;
        	} while(two_halfs++ < 1);
        }
        return buf.toString();
    }
}
