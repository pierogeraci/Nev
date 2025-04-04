
package it.softstrategy.nevis.discovery;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.MulticastSocket;
import java.net.SocketTimeoutException;
import java.net.URLEncoder;
import java.net.UnknownHostException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


/**
 * @author lgalati
 *
 */
public class NevisServiceResponder implements Runnable {
	
	private static final Logger LOG = LogManager.getLogger(NevisServiceResponder.class.getName());
	
	protected static InetAddress multicastAddressGroup;
	protected static int multicastPort;

	static {
		try {
			multicastAddressGroup = InetAddress.getByName(NevisServiceConstants.MULTICAST_ADDRESS_GROUP);
			multicastPort = NevisServiceConstants.MULTICAST_PORT;
		}
		catch (UnknownHostException uhe) {
			LOG.error("Unexpected exception", uhe);
		}
	}
	
	protected String serviceName;
	protected NevisServiceDescription descriptor;
	protected boolean shouldRun = true;
	protected MulticastSocket socket;
	protected DatagramPacket queuedPacket;
	protected DatagramPacket receivedPacket;
	protected Thread thread;
	
	public NevisServiceResponder(String serviceName) {
		this.serviceName = serviceName;
		try {
			socket = new MulticastSocket(multicastPort);
			socket.joinGroup(multicastAddressGroup);
			socket.setSoTimeout(NevisServiceConstants.RESPONDER_SOCKET_TIMEOUT);
		}catch (IOException ioe) {
			LOG.error("Unexpected exception while creating Multicast Socket", ioe);
		}
	}
	

	public NevisServiceDescription getDescriptor() {
		return descriptor;
	}

	
	public void setDescriptor(NevisServiceDescription descriptor) {
		this.descriptor = descriptor;
	}

	public String getServiceName() {
		return serviceName;
	}

	protected String getEncodedServiceName() {
		try {
			return URLEncoder.encode(getServiceName(), "UTF-8");
		}
		catch (UnsupportedEncodingException uee) {
			return null;
		}
	}

	public void setServiceName(String serviceName) {
		this.serviceName = serviceName;
	}

	public void startResponder() {
		if (thread == null || !thread.isAlive()) {
			shouldRun = true;
			thread = new Thread(this, "NevisServiceResponder");
			thread.setDaemon(true);
			thread.start();
		}
	}
	
	public void stopResponder() {
		if (thread != null && thread.isAlive()) {
			shouldRun = false;
			thread.interrupt();
		}
	}

	protected void sendQueuedPacket() {
		if (queuedPacket == null) { return; }
		try {
			socket.send(queuedPacket);
			queuedPacket = null;
		}
		catch (IOException ioe) {
//			System.err.println("Unexpected exception: " + ioe);
//			ioe.printStackTrace();
			LOG.error("Unexpected exception", ioe);
			/* resume operation */
		}
	}
	
	public void run() {

		while (shouldRun) {
			
			byte[] buf = new byte[NevisServiceConstants.DATAGRAM_LENGTH];
			receivedPacket = new DatagramPacket(buf, buf.length);

			try {
				socket.receive(receivedPacket); // note a timeout in effect
				
				if (isQueryPacket()) {
					DatagramPacket replyPacket = getReplyPacket();
					queuedPacket = replyPacket;
					sendQueuedPacket();
				}
			}
			catch (SocketTimeoutException ste) {
				/* ignored; this exception is by design to
				 * break the blocking from socket.receive */
			}
			catch (IOException ioe) {
//				System.err.println("Unexpected exception: "+ ioe);
//				ioe.printStackTrace();
				LOG.error("Unexpected exception", ioe);
				/* resume operation */
			}
			
		}
	}

	protected boolean isQueryPacket() {
		if (receivedPacket == null) {
			return false;
		}
		
		String dataStr = new String(receivedPacket.getData());
		int pos = dataStr.indexOf((char)0);
		if (pos > -1) {
			dataStr = dataStr.substring(0, pos);
		}
		
		if (dataStr.startsWith("SERVICE QUERY " + getEncodedServiceName())) {
			return true;
		}

		return false;
	}
	
	protected DatagramPacket getReplyPacket() {
		StringBuffer buf = new StringBuffer();
		try {
			buf.append("SERVICE REPLY "+ getEncodedServiceName() + " ");
			buf.append(descriptor.toString());
		} catch (NullPointerException npe) {
//			System.err.println("Unexpected exception: "+npe);
//			npe.printStackTrace();
			LOG.error("Unexpected exception", npe);
			return null;
		}
		
		byte[] bytes = buf.toString().getBytes();
		DatagramPacket packet = new DatagramPacket(bytes, bytes.length);
		packet.setAddress(multicastAddressGroup);
		packet.setPort(multicastPort);
		
		return packet;
	}

	
	public void addShutdownHandler() {
		Runtime.getRuntime().addShutdownHook(
				new Thread() {
					public void run() { stopResponder(); }
				});
	}

}
