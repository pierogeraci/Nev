
package it.softstrategy.nevis.onvif;

import java.io.IOException;
import java.io.StringReader;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.MulticastSocket;
import java.net.SocketTimeoutException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.simpleframework.xml.core.ElementException;
import org.simpleframework.xml.core.Persister;
import org.simpleframework.xml.stream.InputNode;
import org.simpleframework.xml.stream.NodeBuilder;

import it.softstrategy.nevis.model.NevisCamera;
import it.softstrategy.nevis.onvif.discovery.EnvelopeProbeMatches;
import it.softstrategy.nevis.onvif.discovery.OnvifDiscoveryUtil;
import it.softstrategy.nevis.onvif.discovery.ProbeMatch;

/**
 * @author lgalati
 *
 */
public class OnvifDeviceBrowser implements Runnable {
	
	private static final Logger LOG = LogManager.getLogger(OnvifDeviceBrowser.class.getName());
	
//	private Integer attempts;
	private Long period;
	private Integer timeout;
	
	
	private InetAddress multicastAddress;
	protected MulticastSocket socket;
	protected DatagramPacket receivedPacket;
	private List<OnvifDiscoveryListener> listeners;
	
	
	
	private ScheduledThreadPoolExecutor executor;
	
	//Costruttore
	public OnvifDeviceBrowser(/*Integer attempts,*/ Long period, Integer timeout) {
		
//		this.attempts = attempts != null ? attempts : OnvifDiscoveryUtil.DEFAULT_ATTEMPTS;
		this.period = period != null ? period : OnvifDiscoveryUtil.DEFAULT_PERIOD;
		this.timeout = timeout != null ? timeout : OnvifDiscoveryUtil.DEFAULT_TIMEOUT;
		listeners = new ArrayList<>();
		executor = (ScheduledThreadPoolExecutor) Executors.newScheduledThreadPool(1);
		try {
			socket = new MulticastSocket(OnvifDiscoveryUtil.PROBE_PORT);
			socket.setSoTimeout(this.timeout);
			multicastAddress = InetAddress.getByName(OnvifDiscoveryUtil.PROBE_IP);
			socket.joinGroup(multicastAddress);
			
		} catch (IOException e) {
			LOG.error("Unexpected IOException", e);
		}
		
	}
	
	public void addOnvifDiscoveryListener(OnvifDiscoveryListener l) {
		if (!listeners.contains(l)) {
			listeners.add(l);
		}
	}
	
	public void removeOnvifDiscoveryListener(OnvifDiscoveryListener l) {
		if (listeners.contains(l)) {
			listeners.remove(l);
		}
	}
	
	public void startSingleDiscovery() {
		if (executor == null || executor.isTerminated()) {
			executor = (ScheduledThreadPoolExecutor) Executors.newScheduledThreadPool(1);
		}
		
		executor.schedule(this, 0L, TimeUnit.SECONDS);
	}
	
	//Metodi pubblici
	public void startDiscovery() {
		if (executor == null || executor.isTerminated()) {
			executor = (ScheduledThreadPoolExecutor) Executors.newScheduledThreadPool(1);
		}
		
		executor.scheduleAtFixedRate(this, 0L, period, TimeUnit.SECONDS);
	}
	
	public void stopDiscovery() {
		if (executor != null) {
			executor.shutdown();
			
			try {
				executor.awaitTermination(1, TimeUnit.SECONDS);
			} catch (InterruptedException e) {
				LOG.warn("", e);
			}
			
			executor = null;
		}
	}
	
	public boolean isWorking() {
		if (executor != null) {
			return !executor.isShutdown();
		}
		
		return false;
	}

	//Runnable
	@Override
	public void run() {
		ArrayList<String> uuidArrayList = new ArrayList<>();
		ArrayList<ProbeMatch> probeMatches = new ArrayList<>();


		sendProbePacket();	


		while (true) {
			try {
				byte[] buf = new byte[OnvifDiscoveryUtil.DATAGRAM_LENGHT];
				receivedPacket = new DatagramPacket(buf, buf.length);
				socket.receive(receivedPacket); // note timeout in effect

				if (isReplyPacket()) {
					ProbeMatch probeMatch = getReplyProbeMatch();

					if (probeMatch != null) {
						if (!uuidArrayList.contains(probeMatch.EndpointReference.Address)) {
							uuidArrayList.add(probeMatch.EndpointReference.Address);
							//							notifyReply(probeMatch);
							probeMatches.add(probeMatch);
							receivedPacket = null;
						}
					}


				}
			} catch (SocketTimeoutException e) {
				/* ignored; this exception is by design to
				 * break the blocking from socket.receive */
				break;
			} catch (ElementException e) {
				LOG.warn("Received an incorrect Response Message ");
//				String responseMessage = new String(receivedPacket.getData());	
//				LOG.warn(responseMessage);
			} catch (Exception e) {
				LOG.error("Unexpected Exception while looking for Onvif Devices", e);
			}


		}

		notifyReply(probeMatches);
	}
	
	private void sendProbePacket() {

		//TODO: come posso controllare l'invio del messaggio di PROBE?
		
		try {			
			String probeMessage = OnvifDiscoveryUtil.getProbeSoapMessage();
			byte[] probeByteArray = probeMessage.getBytes();
			DatagramPacket probePacket = new DatagramPacket(probeByteArray, probeByteArray.length);
			probePacket.setAddress(multicastAddress);		
			probePacket.setPort(OnvifDiscoveryUtil.PROBE_PORT);
			socket.send(probePacket);
		} catch (IOException ioe) {
			LOG.error("Unexpected exception!", ioe);
			/* resume operation */
		}
		
	}

	private boolean isReplyPacket() {

		if (receivedPacket == null) {
			return false;
		}
		
		//TODO: make this more complex :D
		return true;
	}
	
	private ProbeMatch getReplyProbeMatch() throws Exception {
		String responseMessage = new String(receivedPacket.getData());
//		LOG.debug("response message: " + responseMessage);
		
		StringReader stringReader = new StringReader(responseMessage);
		InputNode localInputNode = NodeBuilder.read(stringReader);
		EnvelopeProbeMatches localEnvelopeProbeMatches = 
				new Persister().read(EnvelopeProbeMatches.class, localInputNode);
		
		
		ProbeMatch localProbeMatch = null;
		if (localEnvelopeProbeMatches.BodyProbeMatches.ProbeMatches.listProbeMatches.size() > 0) {
			localProbeMatch = 
					localEnvelopeProbeMatches.BodyProbeMatches.ProbeMatches.listProbeMatches.get(0);
		}	
		
		LOG.trace("Probe matches with UUID:\n" + localProbeMatch.EndpointReference.Address +
    			 " URL: " + localProbeMatch.XAddrs);
		
		return localProbeMatch;
	}
	
	protected void notifyReply(List<ProbeMatch> probeMatches) {
		List<NevisCamera> discoveredCameras = new ArrayList<>();
		if (probeMatches != null) {
//			LOG.debug(probeMatches);
			for (ProbeMatch probeMatch : probeMatches) {
				NevisCamera discoveredCamera = OnvifDiscoveryUtil.toNevisCamera(probeMatch);
				discoveredCameras.add(discoveredCamera);
			}
		}
		
		
		if (discoveredCameras.size() > 0) {
			for ( OnvifDiscoveryListener l : listeners ) {
				l.handleOnvifDiscoveryResult(discoveredCameras);
			}
		}
		
		
	}

	

}
