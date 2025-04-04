package it.softstrategy.nevis;

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.nio.file.Files;
import java.security.GeneralSecurityException;
import java.security.Key;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Base64;
import java.util.Date;
import java.util.Scanner;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

public class LManager {
	
	private static final int RSA_KEYSIZE = 2048;
	private static final int AES_KEYSIZE = 256;

	public static void main(String[] args) {

		try {
			if (args[0].equals("-genRSAkey")) {
				KeyPairGenerator pairgen = KeyPairGenerator.getInstance("RSA");
				SecureRandom random = new SecureRandom();
				pairgen.initialize(RSA_KEYSIZE, random);
				KeyPair keyPair = pairgen.generateKeyPair();			
				
				//Chiave Pubblica
				writeToFile(args[1], keyPair.getPublic().getEncoded());
				
				//Chiave Privata
				writeToFile(args[2], keyPair.getPrivate().getEncoded());
				
			}
			else if (args[0].equals("-genAESkey")) {
				KeyGenerator keygen = KeyGenerator.getInstance("AES");
				keygen.init(AES_KEYSIZE);
				SecretKey secretKey = keygen.generateKey();		
				
				//Chiave Simmetrica
				writeToFile(args[1], secretKey.getEncoded());
				
				writeToTextFile(args[1] + ".txt", secretKey.getEncoded());
			} 
			else if (args[0].equals("-sn")) {		
				Scanner scanner = new Scanner(System.in);
				System.out.print("Numero di telecamere: ");
				String numCams = scanner.nextLine();
				System.out.print("Societa: ");
				String societa = scanner.nextLine();	
				System.out.print("MacAddress: ");
				String macAddress = scanner.nextLine();		
				scanner.close();
				//String serialNumber=getSerialNumber(numCams,societa);
				String serialNumber=getSerialNumber(numCams,societa,macAddress);
				System.out.println(serialNumber);
			}
			else if (args[0].equals("-encryptRSA")) {
//				System.out.println(args[0] + " - " + args[1] + " - " + args[2] + " - " + args[3] );
				String serialNumber = args[1];
	
				//load RSA public key
				PublicKey publicKey = loadPublicKey(args[2]);
	
				Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1PADDING");
				cipher.init(Cipher.ENCRYPT_MODE, publicKey);
				
//				crypt(serialNumber, out, cipher);
				byte[] encryptedData = cipher.doFinal(serialNumber.getBytes());
				
				DataOutputStream out = new DataOutputStream(new FileOutputStream(args[3]));
				out.write(encryptedData);
				out.close();
			} else if (args[0].equals("-encryptAES")) {
				//load AES simmetric key  
				SecretKey secretKey = loadSecretKey(args[1]);
	            
	            Cipher cipher = Cipher.getInstance("AES");
				cipher.init(Cipher.ENCRYPT_MODE, secretKey);
				
				//load content to encrypt
				byte[] inputBytes = Files.readAllBytes(new File(args[2]).toPath());
	            
				//execute encryption
	            byte[] outputBytes = cipher.doFinal(inputBytes);
	            
	            //save encrypted content
	            writeToFile(args[3], outputBytes);
	            
			} else if (args[0].equals("-decryptAES")) {
				
	            //Carico la chiave da file .txt
//	            BufferedReader reader = new BufferedReader(new FileReader(args[1]));
//	            String encodedKey = reader.readLine() ;
//	            reader.close();
//	            byte[] decodedKey = Base64.getDecoder().decode(encodedKey);
//	            SecretKey secretKey = new SecretKeySpec(decodedKey, 0, decodedKey.length, "AES");
				
				//load AES simmetric key  
				SecretKey secretKey = loadSecretKey(args[1]);
	            
	            Cipher cipher = Cipher.getInstance("AES");
				cipher.init(Cipher.DECRYPT_MODE, secretKey);

				//load content to decrypt
				byte[] inputBytes = Files.readAllBytes(new File(args[2]).toPath());
	            
				//execute decryption
	            byte[] outputBytes = cipher.doFinal(inputBytes);
	            
	            //save decrypted content
	            writeToFile(args[3], outputBytes);
	            
			} else if (args[0].equals("-decryptRSA")) {

				// load RSA private key
				PrivateKey privateKey = loadPrivateKey(args[1]);
				
				//load license
//				File inputFile = new File(args[2]);
//				boolean exists = inputFile.exists();
//				long lenght = inputFile.length();
//				FileInputStream fis = new FileInputStream(inputFile);
//				byte[] fbytes = new byte[(int) inputFile.length()];
//				fis.read(fbytes);
//				fis.close();
				
				byte[] licenseBytes = Files.readAllBytes(new File(args[2]).toPath());
				
				Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1PADDING");
				cipher.init(Cipher.DECRYPT_MODE, privateKey);
				byte[] decryptedBytes = cipher.doFinal(licenseBytes);
				
				StringBuilder sb = new StringBuilder();
				
				for (byte b: decryptedBytes) {
					if (b != 0) sb.append ((char) b);
				}
				System.out.println(sb.toString());
//				String serialNumber = decrypt(in, cipher);
//				System.out.println(serialNumber);
//				in.close();
			} else {
				System.out.println("Parametri di input non riconosciuto");
			}
		} catch (IOException e) {
			e.printStackTrace();
		} catch (GeneralSecurityException e) {
			e.printStackTrace();
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}
	
	public static void crypt(String in, OutputStream out, Cipher cipher)
			throws IOException, GeneralSecurityException {
		int blockSize = cipher.getBlockSize();
		int outputSize = cipher.getOutputSize(blockSize);
		byte[] outBytes = new byte[outputSize];

		int inLength = in.length();
		byte[] inBytes = StringToByteArray(in);
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
		StringBuilder sb = new StringBuilder();
		
		int inLength = 0;
	    boolean more = true;
	    while (more) {
	    	inLength = in.read(inBytes);
	    	if (inLength == blockSize) {
	    		int outLength = cipher.update(inBytes, 0, blockSize, outBytes);
//	    	    for (byte b: outBytes) {
//	    	    	if (b != 0) sb.append ((char) b);
//	    	    }
	    		for (int i = 0; i < outBytes.length; i++) {
	    			byte b = outBytes[i];
	    			if (b != 0) {
	    				sb.append((char) b);
	    			}
	    		}
	    	} 
	    	else more = false;
	    }
	    if (inLength > 0) 
	    	outBytes = cipher.doFinal(inBytes, 0, inLength);
	    else 
	    	outBytes = cipher.doFinal();
//	    for (byte b: outBytes)
//	    	if (b != 0) sb.append ((char) b);
	    for (int i = 0; i < outBytes.length; i++) {
			byte b = outBytes[i];
			if (b != 0) {
				sb.append((char) b);
			}
		}
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
	
	private static String getSerialNumber(String numCams, String societa, String macAddress) throws ParseException {
		String serialNumber="";
		//serialNumber+=System.getProperties().getProperty("os.arch");
		//serialNumber+=System.getProperties().getProperty("os.name");
		//serialNumber+=System.getProperties().getProperty("os.version");
		serialNumber += numCams + "|";
		serialNumber += societa + "|";
		//serialNumber+=System.getProperties().getProperty("sun.arch.data.model");
		//serialNumber+=System.getenv().get("PROCESSOR_REVISION");
		//serialNumber+=System.getenv().get("PROCESSOR_LEVEL");
		//serialNumber+=System.getenv().get("NUMBER_OF_PROCESSORS");
		//serialNumber+=System.getProperties().getProperty("sun.cpu.isalist");
		//serialNumber += getMacAddress() + "|";
		serialNumber+=macAddress+ "|";
		SimpleDateFormat format = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss");
		String dateString = "01-01-2100 00:00:00";
		Date expireDate = format.parse(dateString);
		serialNumber += expireDate.getTime();
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
	
	
	
	
	//-------------------------
	public static void writeToFile(String path, byte[] key) throws IOException {
		File f = new File(path);
//		f.getParentFile().mkdirs();

		FileOutputStream fos = new FileOutputStream(f);
		fos.write(key);
		fos.flush();
		fos.close();
	}
	
	public static void writeToTextFile(String path, byte[] key) throws IOException {
		File f = new File(path);
		
		String keyString = Base64.getEncoder().encodeToString(key);
		PrintWriter pw = new PrintWriter(new FileOutputStream(f));
		pw.println(keyString);
		pw.close();
	}
	
	public static PublicKey loadPublicKey(String filename) throws Exception {
		byte[] keyBytes = Files.readAllBytes(new File(filename).toPath());
		X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
		KeyFactory kf = KeyFactory.getInstance("RSA");
		return kf.generatePublic(spec);
	}
	
	public static PrivateKey loadPrivateKey(String filename) throws Exception {
		byte[] keyBytes = Files.readAllBytes(new File(filename).toPath());
		PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(keyBytes);
		KeyFactory kf = KeyFactory.getInstance("RSA");
		return kf.generatePrivate(spec);
	}
	
	public static SecretKey loadSecretKey(String filename) throws IOException {
		byte[] keyBytes = Files.readAllBytes(new File(filename).toPath());
		return new SecretKeySpec(keyBytes, "AES");
	}

}
