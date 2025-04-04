package it.softstrategy.nevis.discovery;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.MulticastSocket;
import java.net.SocketTimeoutException;
import java.net.URLEncoder;
import java.net.UnknownHostException;
import java.util.StringTokenizer;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Vector;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.util.IPUtil;


/**
 * @author lgalati
 *
 */
public class NevisServiceBrowser implements Runnable {
	
	private static final Logger LOG = LogManager.getLogger(NevisServiceBrowser.class.getName());
	
	
	protected static InetAddress multicastAddressGroup;
	protected static int multicastPort;

	static {
		try {
			multicastAddressGroup = InetAddress.getByName(NevisServiceConstants.MULTICAST_ADDRESS_GROUP);
			multicastPort = NevisServiceConstants.MULTICAST_PORT;
		}
		catch (UnknownHostException uhe) {
			LOG.error("Unexpected exception!", uhe);
		}
	}

	protected String serviceName;
	protected boolean shouldRun = true;
	protected MulticastSocket socket;
	protected DatagramPacket queuedPacket;
	protected DatagramPacket receivedPacket;
	protected Vector<NevisServiceBrowserListener> listeners;
	protected Thread thread;
	protected Timer timer;
	
	
	public NevisServiceBrowser() {
		
		try {
			socket = new MulticastSocket(multicastPort);
			socket.joinGroup(multicastAddressGroup);
			socket.setSoTimeout(NevisServiceConstants.BROWSER_SOCKET_TIMEOUT);			
		}catch (IOException ioe) {
			LOG.error("Unexpected exception!", ioe);
		}
		
		listeners = new Vector<NevisServiceBrowserListener>();
	}
	
	public String getServiceName() {
		return serviceName;
	}
	
	protected String getEncodedServiceName() {
		try {
			return URLEncoder.encode(getServiceName(),"UTF-8");
		}
		catch (UnsupportedEncodingException uee) {
			return null;
		}
	}

	public void setServiceName(String serviceName) {
		this.serviceName = serviceName;
	}

	public void addServiceBrowserListener(NevisServiceBrowserListener l) {
		if (! listeners.contains(l)) {
			listeners.add(l);
		}
	}
	
	public void removeServiceBrowserListener(NevisServiceBrowserListener l) {
		listeners.remove(l);
	}

	public void startLookup() {
		if (timer == null) {
			timer = new Timer("QueryTimer");
			timer.scheduleAtFixedRate(new QueryTimerTask(), 0L , NevisServiceConstants.BROWSER_QUERY_INTERVAL);
		}
	}

	public void startSingleLookup() {
		if (timer == null) {
			timer = new Timer("QueryTimer");
			timer.schedule(new QueryTimerTask(), 0L);
			timer = null;
		}
	}
	
	public void stopLookup() {
		if (timer != null) {
			timer.cancel();
			timer = null;
		}
	}
	
	protected void notifyReply(NevisServiceDescription descriptor) {
		for (NevisServiceBrowserListener l : listeners) {
			l.serviceReply(descriptor);
		}
	}

	public void startListen() {
		if (thread == null) {
			shouldRun = true;
			thread = new Thread(this, "NevisServiceBrowser");
			thread.start();
		}
	}
	
	public void stopListen() {
		if (thread != null) {
			shouldRun = false;
			thread.interrupt();
			thread = null;
		}
	}

	public void run() {

		while (shouldRun) {
			/* listen (briefly) for a reply packet */
			try {
				byte[] buf = new byte[NevisServiceConstants.DATAGRAM_LENGTH];
				receivedPacket = new DatagramPacket(buf, buf.length);
				socket.receive(receivedPacket); // note timeout in effect
				
				
				if (isReplyPacket()) {
					NevisServiceDescription descriptor;

					/* notes on behavior of descriptors.indexOf(...)
					 * ServiceDescriptor objects check for 'equals()'
					 * based only on the instanceName field. An update
					 * to a descriptor implies we should replace an
					 * entry if we already have one. (Instead of bothing
					 * with the details to determine new vs. update, just
					 * quickly replace any current descriptor.)
					 */

					descriptor = getReplyDescriptor();
					if (descriptor != null) {
						notifyReply(descriptor);
						receivedPacket = null;
					}
				
				}
				
			}
			catch (SocketTimeoutException ste) {
				/* ignored; this exception is by design to
				 * break the blocking from socket.receive */
			}
			catch (IOException ioe) {
//				System.err.println("Unexpected exception: "+ioe);
//				ioe.printStackTrace();
				LOG.error("Unexpected exception!", ioe);
				/* resume operation */
			}
			
			sendQueuedPacket();			
		}
	}

	protected void sendQueuedPacket() {
		if (queuedPacket == null) { return; }
		try {
			socket.send(queuedPacket);
			queuedPacket = null;
		} catch (IOException ioe) {
//			System.err.println("Unexpected exception: "+ioe);
//			ioe.printStackTrace();
			LOG.error("Unexpected exception!", ioe);
			/* resume operation */
		}
	}

	protected boolean isReplyPacket(){ 
		if (receivedPacket == null) {
			return false;
		}
		
		String senderIpAddress = receivedPacket.getAddress().getHostAddress();
		if (senderIpAddress.equals(IPUtil.getMyIpAddress())) {
			return false;
		}
		
		String dataStr = new String(receivedPacket.getData());
		int pos = dataStr.indexOf((char)0);
		if (pos > -1) {
			dataStr = dataStr.substring(0, pos);
		}
		
		/* REQUIRED TOKEN TO START */
		if (dataStr.startsWith("SERVICE REPLY " + getEncodedServiceName())) {
			return true;
		}

		return false;
	}
	
	protected NevisServiceDescription getReplyDescriptor() {
		String dataStr = new String(receivedPacket.getData());
		int pos = dataStr.indexOf((char)0);
		if (pos >- 1) {
			dataStr = dataStr.substring(0, pos);
		}
		
		StringTokenizer tokens = new StringTokenizer(dataStr.substring(15 + getEncodedServiceName().length()));
		if (tokens.countTokens() == 3) {
			return NevisServiceDescription.parse(tokens.nextToken(),
					tokens.nextToken(), tokens.nextToken());
		} else {
			return null;
		}
	}
	
	protected DatagramPacket getQueryPacket() {
		StringBuffer buf = new StringBuffer();
		buf.append("SERVICE QUERY " + getEncodedServiceName());
		
		byte[] bytes = buf.toString().getBytes();
		DatagramPacket packet = new DatagramPacket(bytes, bytes.length);
		packet.setAddress(multicastAddressGroup);
		packet.setPort(multicastPort);
		
		return packet;
	}

	
	private class QueryTimerTask extends TimerTask {
		public void run() {
			DatagramPacket packet = getQueryPacket();
			if (packet != null) {
				queuedPacket = packet;
			}
		}
	}

}
