
package it.softstrategy.nevis.discovery;

import java.io.UnsupportedEncodingException;
import java.net.InetAddress;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.net.UnknownHostException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


/**
 * @author lgalati
 *
 */
public class NevisServiceDescription {
	
	private static final Logger LOG = LogManager.getLogger(NevisServiceDescription.class.getName());
	
	private String instanceName;
	private int port;
	private InetAddress address;
	
	
	public InetAddress getAddress() {
		return address;
	}
	
	public void setAddress(InetAddress serviceAddress) {
		this.address = serviceAddress;
	}
	
	protected String getAddressAsString() {
		return getAddress().getHostAddress();
	}
	
	public String getInstanceName() {
		return instanceName;
	}
	
	public void setInstanceName(String serviceDescription) {
		this.instanceName = serviceDescription;
	}

	protected String getEncodedInstanceName() {
		try {
			return URLEncoder.encode(getInstanceName(), "UTF-8");
		} catch (UnsupportedEncodingException uee) {
			return null;
		}
	}

	public int getPort() {
		return port;
	}
	
	public void setPort(int servicePort) {
		this.port = servicePort;
	}

	protected String getPortAsString() {
		return " "+ getPort();
	}

	public String toString() {
		StringBuffer buf = new StringBuffer();
		buf.append(getEncodedInstanceName());
		buf.append(" ");
		buf.append(getAddressAsString());
		buf.append(" ");
		buf.append(getPortAsString());
		return buf.toString();
	}
	
	public boolean equals(Object o) {
		if (o == this) { return true; }
		if (! (o instanceof NevisServiceDescription)) { return false; }
		NevisServiceDescription descriptor = (NevisServiceDescription)o;
		return descriptor.getInstanceName().equals(getInstanceName());
	}
	
	public int hashCode() {
		return getInstanceName().hashCode();
	}

	public int compareTo(NevisServiceDescription nsd) throws ClassCastException {
		if (nsd == null) { throw new NullPointerException(); }
		if (nsd == this) { return 0; }

		return getInstanceName().compareTo(nsd.getInstanceName());
	}
	
	public static NevisServiceDescription parse(String encodedInstanceName,
			String addressAsString, String portAsString) {
		
		NevisServiceDescription descriptor = new NevisServiceDescription();
		try {
			String name = URLDecoder.decode(encodedInstanceName, "UTF-8");
			if (name == null || name.length() == 0) {
				/* warning: check API docs for exact behavior of 'decode' */
				return null;
			}
			descriptor.setInstanceName(name);
		} catch (UnsupportedEncodingException uee) {
//			System.err.println("Unexpected exception: " + uee);
//			uee.printStackTrace();
			LOG.error("Unexpected exception", uee);
			return null;
		}
		
		try {
			InetAddress addr = InetAddress.getByName(addressAsString);
			descriptor.setAddress(addr);
		} catch (UnknownHostException uhe) {
//			System.err.println("Unexpected exception: "+uhe);
//			uhe.printStackTrace();
			LOG.error("Unexpected exception", uhe);
			return null;
		}

		try {
			int p = Integer.parseInt(portAsString);
			descriptor.setPort(p);
		} catch (NumberFormatException nfe) {
//			System.err.println("Unexpected exception: " + nfe);
//			nfe.printStackTrace();
			LOG.error("Unexpected exception", nfe);
			return null;
		}
		
		return descriptor;
	}

}
