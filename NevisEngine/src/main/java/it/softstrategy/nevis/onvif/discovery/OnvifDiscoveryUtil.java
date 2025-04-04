package it.softstrategy.nevis.onvif.discovery;

import java.net.MalformedURLException;
import java.net.URL;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.model.NevisCamera;
import it.softstrategy.nevis.onvif.soap.OnvifDevice;
import it.softstrategy.nevis.util.IPUtil;
import it.softstrategy.nevis.util.MacAddressUtil;

public class OnvifDiscoveryUtil {
	
	private static final Logger LOG = LogManager.getLogger(OnvifDiscoveryUtil.class.getName());
	
	public static final String PROBE_IP = "239.255.255.250";
	public static final String PROBE_MESSAGE = 
			"<s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:a=\"http://schemas.xmlsoap.org/ws/2004/08/addressing\">"
			+ "<s:Header>"
			+ "<a:Action s:mustUnderstand=\"1\">http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</a:Action>"
			+ "<a:MessageID>uuid:21859bf9-6193-4c8a-ad50-d082e6d296ab</a:MessageID>"
			+ "<a:ReplyTo><a:Address>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</a:Address></a:ReplyTo>"
			+ "<a:To s:mustUnderstand=\"1\">urn:schemas-xmlsoap-org:ws:2005:04:discovery</a:To>"
			+ "</s:Header>"
			+ "<s:Body>"
			+ "<Probe xmlns=\"http://schemas.xmlsoap.org/ws/2005/04/discovery\">"
			+ "<d:Types xmlns:d=\"http://schemas.xmlsoap.org/ws/2005/04/discovery\" xmlns:dp0=\"http://www.onvif.org/ver10/network/wsdl\">dp0:NetworkVideoTransmitter</d:Types>"
			+ "</Probe>"
			+ "</s:Body>"
			+ "</s:Envelope>";
    public static final int PROBE_PORT = 3702;
    public static final String SCOPE_NAME = "onvif://www.onvif.org/name/";
    public static final String SCOPE_HARDWARE = "onvif://www.onvif.org/hardware/";
    public static final int DEFAULT_TIMEOUT = 4000;
	public static final int DATAGRAM_LENGHT = 4096;
	public static final int DEFAULT_PERIOD = 10; //Espresso in minuti
	public static final int DEFAULT_ATTEMPTS = 5;
	
    
    
    
    public static String getProbeSoapMessage() {
    	return PROBE_MESSAGE.replaceFirst(
    			"<a:MessageID>uuid:.+?</a:MessageID>", "<a:MessageID>uuid:"
    					+ UUID.randomUUID().toString() + "</a:MessageID>");
    }
    
    public static NevisCamera toNevisCamera(ProbeMatch probeMatch) {
    	NevisCamera discoveredCamera = null;
    	try {
		    
		    String[] scopeArray = probeMatch.Scopes.split("\\s");
		    String scopeModel = "";
		    String scopeVendor = "";
		    for (String scope : scopeArray) {
				final String URL_SPACE = "%20";
				if (scope.contains(OnvifDiscoveryUtil.SCOPE_NAME)) {
				    scopeVendor = scope.replace(OnvifDiscoveryUtil.SCOPE_NAME, "").replace(URL_SPACE, " ");
				}
				if (scope.contains(OnvifDiscoveryUtil.SCOPE_HARDWARE)) {
				    scopeModel = scope.replace(OnvifDiscoveryUtil.SCOPE_HARDWARE, "").replace(URL_SPACE, " ");
				}
		    }
	
		    // Make the ONVIF scopes match vendor + model pattern
		    if (scopeVendor.contains(scopeModel)) {
				scopeVendor = scopeVendor.replace(scopeModel, "").replace(" ", "");
		    }
		    
		    String[] urlArray = probeMatch.XAddrs.split("\\s");
		    try{
		    	String ipAddressString = "";
				int httpPort = 0;
				for (String urlString : urlArray) {
				    URL localURL = new URL(urlString);
				    String urlHost = localURL.getHost();
				    // Make sure it's a valid local IPv4 address
				    if (IPUtil.isLocalIpv4(urlHost)) {
						ipAddressString = urlHost;
						httpPort = localURL.getPort();
						if (httpPort == -1) {
						    httpPort = 80;
						}
						break; // Only break when it gets a valid address
				    } else {
				    	LOG.info("Discarded a ONVIF IP: " + urlHost);
				    }
				}
				
				discoveredCamera = new NevisCamera();
				discoveredCamera.setIpAddress(ipAddressString);
				discoveredCamera.setHttpPort(httpPort);
				if (!scopeVendor.isEmpty()) {
					discoveredCamera.setVendor(scopeVendor.toLowerCase());
				}
				if (!scopeModel.isEmpty()) {
					discoveredCamera.setModel(scopeModel.toLowerCase());
				}
				String macAddress = MacAddressUtil.getByIpLinux(ipAddressString);
				discoveredCamera.setMacAddress(macAddress);
				
				String nowString = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
				
				discoveredCamera.setFirstSeen(nowString);
				discoveredCamera.setLastSeen(nowString);
//				discoveredCamera.setInputConnectors(new OnvifDevice(ipAddressString).getInputConnectors());
				discoveredCamera.setIsOnvif(Boolean.TRUE);
				
				
		    } catch (MalformedURLException e) {
		    	LOG.error("Cannot parse xAddr: " + probeMatch.XAddrs, e);
			}
		
    	} catch (Exception e) {
			LOG.error("Parse ONVIF search result error", e);
		}
    	return discoveredCamera;
    }

}
