package it.softstrategy.nevis.util;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;
import java.util.regex.Pattern;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class IPUtil {
	
	public static final Logger LOG = LogManager.getLogger(IPUtil.class.getName());
	
	public static boolean isLocalIpv4(String ip) {
		final String REGULAR_EXPRESSION_LOCAL_IP = "(127.0.0.1)|(192.168.*$)|(172.1[6-9].*$)|(172.2[0-9].*$)|(172.3[0-1].*$)|(10.*$)";
		return ip.matches(REGULAR_EXPRESSION_LOCAL_IP);
	}
	
	public static String getMyIpAddress() {
		NetworkInterface iface = null;
    	String ethr;
    	String myIp = "";
    	String regex = "^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." +	"([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." + "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." + "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";
    	
    	try {
    		for(Enumeration<?> ifaces = NetworkInterface.getNetworkInterfaces();ifaces.hasMoreElements();){
    			iface = (NetworkInterface)ifaces.nextElement();
    			ethr = iface.getDisplayName();

    			if (Pattern.matches("eth[0-9]", ethr)){
    				InetAddress ia = null;
    				for(Enumeration<?> ips = iface.getInetAddresses();ips.hasMoreElements();){
    					ia = (InetAddress)ips.nextElement();
    					if (Pattern.matches(regex, ia.getCanonicalHostName())){
    						myIp = ia.getCanonicalHostName();
    					}
    				}
    			}
    		}
    	} catch (SocketException e) {
    		LOG.error("Can't find my ip address", e);
		}
    	
    	return myIp;
	}
	
	public static InetAddress getMyInetAddress() {
		NetworkInterface iface = null;
    	String ethr;
    	InetAddress myIp = null;
    	String regex = "^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." +	"([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." + "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." + "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";
    	
    	try {
    		for(Enumeration<?> ifaces = NetworkInterface.getNetworkInterfaces();ifaces.hasMoreElements();){
    			iface = (NetworkInterface)ifaces.nextElement();
    			ethr = iface.getDisplayName();

    			if (Pattern.matches("eth[0-9]", ethr)){
    				InetAddress ia = null;
    				for(Enumeration<?> ips = iface.getInetAddresses();ips.hasMoreElements();){
    					ia = (InetAddress)ips.nextElement();
    					if (Pattern.matches(regex, ia.getCanonicalHostName())){
    						myIp = ia/*.getCanonicalHostName()*/;
    					}
    				}
    			}
    		}
    	} catch (SocketException e) {
    		LOG.error("Can't find my ip address", e);
		}
    	
    	return myIp;
	}

}
