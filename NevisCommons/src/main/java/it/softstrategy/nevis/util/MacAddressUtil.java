package it.softstrategy.nevis.util;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class MacAddressUtil {
	
	private static final Logger LOG = LogManager.getLogger(MacAddressUtil.class);

	 /**
     * Read hardware address from ARP table by specified IP address(work for
     * Android only). If no MAC address associated, return 00:00:00:00:00:00.
     * 
     * By Mario Squillace
     * 
     * @param ip
     *            host IP address
	 * @throws IOException 
     */
    @SuppressWarnings("resource")
	public static String getByIpLinux(String ip) throws IOException {
    	String mac = "";
    	
    	int count = 0;
    	int maxTries = 3;
    	while(true) {
    	    try {
        		String systemInput = "";
        		Runtime.getRuntime().exec("ping -c 1 " + ip);
        		//to renew the system table before querying
        		Runtime.getRuntime().exec("arp");
        		Scanner s = new Scanner(Runtime.getRuntime().exec("arp " + ip).getInputStream()).useDelimiter("\\A");
        		systemInput = s.next();
        		//String mac = "";
        		Pattern pattern = Pattern.compile("\\s{0,}([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})");
        		Matcher matcher = pattern.matcher(systemInput);
        		
        		if (matcher.find()) {
        			mac = mac + matcher.group().replaceAll("\\s", "");
        			return mac;
        		}
    	    } catch (IOException e) {
    	        // handle exception
    	        if (++count == maxTries) throw e;
        		LOG.error("", e);
    	    }
    	}
    }
    
    public static String getByInetAddress(InetAddress ip) throws IOException {
    	String address = "";

//		InetAddress ip = IPUtil.getMyInetAddress();
//		InetAddress ip = InetAddress.getLocalHost();
    	NetworkInterface network = NetworkInterface.getByInetAddress(ip);
    	byte[] mac = network.getHardwareAddress();
    	StringBuilder sb = new StringBuilder();
    	for (int i = 0; i < mac.length; i++) {
    		//sb.append(String.format("%02X%s", mac[i], (i < mac.length - 1) ? "-" : ""));
    		sb.append(String.format("%02X%s", mac[i], (i < mac.length - 1) ? "" : ""));
    	}
    	address = sb.toString();

    	return address;
    }
    
    public static List<String> getHardwareAddresses() throws SocketException {
    	List<String> addresses = new ArrayList<>();
		
    	if (System.getProperty("os.name").equals("Linux")) {

			// Read all available device names
			List<String> devices = new ArrayList<>();
			Pattern pattern = Pattern.compile("^ *(.*):");
			try (FileReader reader = new FileReader("/proc/net/dev")) {
				BufferedReader in = new BufferedReader(reader);
				String line = null;
				while( (line = in.readLine()) != null) {
					Matcher m = pattern.matcher(line);
					if (m.find()) {
						devices.add(m.group(1));
					}
				}
			} catch (IOException e) {
//				e.printStackTrace();
				LOG.error("Unexpected exception while reading system info", e);
			}

			// read the hardware address for each device
			for (String device : devices) {
				NetworkInterface iface = NetworkInterface.getByName(device);
				boolean isLoopback = iface != null && iface.isLoopback();
				if ( !isLoopback ) {
					try (FileReader reader = new FileReader("/sys/class/net/" + device + "/address")) {
						BufferedReader in = new BufferedReader(reader);
						String addr = in.readLine();
						addr = addr.replaceAll(":", "");
//						System.out.println(String.format("%5s: %s", device, addr));
						addresses.add(addr);
					} catch (IOException e) {
//						e.printStackTrace();
						LOG.error("Unexpected exception while reading system info", e);
					}
				}
			}

		} else {
			// use standard API for Windows & Others (need to test on each platform, though!!)
			//TODO: complete
		}
		
		return addresses;
    }

}
