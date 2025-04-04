package it.softstrategy.nevis.onvif.discovery;

import java.io.StringReader;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.simpleframework.xml.core.Persister;
import org.simpleframework.xml.stream.InputNode;
import org.simpleframework.xml.stream.NodeBuilder;

import it.softstrategy.nevis.model.NevisCamera;
import it.softstrategy.nevis.onvif.soap.OnvifDevice;
import it.softstrategy.nevis.util.IPUtil;
import it.softstrategy.nevis.util.MacAddressUtil;

public class OnvifDiscovery {
	
	private static final Logger LOG = LogManager.getLogger(OnvifDiscovery.class);
	
	private Integer socketTimeout;

	public OnvifDiscovery() {
	}

	public OnvifDiscovery(Integer socketTimeout) {
		this.socketTimeout = socketTimeout;
	}
	
	public List<NevisCamera> probe() {
		
		LOG.debug("Probe start");
		
		List<NevisCamera> discoveredCameras = new ArrayList<>();
		DatagramSocket datagramSocket = null;
		try {
			datagramSocket = new DatagramSocket();
			datagramSocket.setSoTimeout(socketTimeout == null ? OnvifDiscoveryUtil.DEFAULT_TIMEOUT : socketTimeout);
			InetAddress multicastAddress = InetAddress.getByName(OnvifDiscoveryUtil.PROBE_IP);
			
			if (multicastAddress == null) {
				LOG.warn("InetAddress.getByName() for multicast returns null");
				return discoveredCameras;
			}

			// Send the UDP probe message
			String soapMessage = OnvifDiscoveryUtil.getProbeSoapMessage();

			byte[] soapMessageByteArray = soapMessage.getBytes();
			DatagramPacket datagramPacketSend = new DatagramPacket(soapMessageByteArray, soapMessageByteArray.length,
					multicastAddress, OnvifDiscoveryUtil.PROBE_PORT);
			datagramSocket.send(datagramPacketSend);

			ArrayList<String> uuidArrayList = new ArrayList<String>();

			while (true) {
				byte[] responseMessageByteArray = new byte[4000];
				DatagramPacket datagramPacketRecieve = new DatagramPacket(
						responseMessageByteArray,
						responseMessageByteArray.length);
				datagramSocket.receive(datagramPacketRecieve);

				String responseMessage = new String(datagramPacketRecieve.getData());
//				LOG.debug("\nResponse Message:\n"	+ responseMessage);

				StringReader stringReader = new StringReader(responseMessage);
				InputNode localInputNode = NodeBuilder.read(stringReader);
				EnvelopeProbeMatches localEnvelopeProbeMatches = 
						new Persister().read(EnvelopeProbeMatches.class, localInputNode);
				if (localEnvelopeProbeMatches.BodyProbeMatches.ProbeMatches.listProbeMatches.size() <= 0) {
					continue;
				}

				ProbeMatch localProbeMatch = 
						localEnvelopeProbeMatches.BodyProbeMatches.ProbeMatches.listProbeMatches.get(0);
				
				LOG.trace("Probe matches with UUID:\n" + localProbeMatch.EndpointReference.Address +
		    			 " URL: " + localProbeMatch.XAddrs);
		    			

				if (uuidArrayList.contains(localProbeMatch.EndpointReference.Address)) {
					LOG.trace("ONVIFDiscovery: Address " + localProbeMatch.EndpointReference.Address + " already added"); 
		    				 
					continue;
				}

				uuidArrayList.add(localProbeMatch.EndpointReference.Address);

				NevisCamera discoveredCamera = probeMatch2NevisCamera(localProbeMatch);

				discoveredCameras.add(discoveredCamera);
			}
			    
		} catch (Exception e) {
			// ONVIF timeout. Don't print anything.
		} finally {
			if (datagramSocket != null && !datagramSocket.isClosed()) {
				datagramSocket.close();
			}
		}
		
		LOG.debug("Probe end - returning discovered cameras");
		return discoveredCameras;
	}

	private NevisCamera probeMatch2NevisCamera(ProbeMatch probeMatch) {
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
