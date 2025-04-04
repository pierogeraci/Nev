package it.softstrategy.nevis.license.util;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class NetworkUtil {
	
	
	
	public static String getMacAddress() {
		
		String macAddress = null;
		
		try {
			NetworkInterface nic = NetworkInterface.getByName("eth0");
			if (nic != null) {
				byte[] hardwareAddr = nic.getHardwareAddress();
				StringBuilder sb = new StringBuilder();
				for (int i = 0; i < hardwareAddr.length; i++) {
					sb.append(String.format("%02X", hardwareAddr[i]));
				}
				macAddress = sb.toString();
			}
		} catch (SocketException e) {
			//e.printStackTrace();
		}
		
		return macAddress;
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
				System.err.println("Unexpected exception while reading system info");
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
						System.err.println("Unexpected exception while reading system info");
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
