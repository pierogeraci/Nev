package it.softstrategy.nevis.discovery;

/**
 * @author lgalati
 *
 */
public class NevisServiceConstants {
	
	// the server and client must match up on the following values...
	public static final String MULTICAST_ADDRESS_GROUP = "224.0.0.3";
	public static final int MULTICAST_PORT = 8765;
	public static final int DATAGRAM_LENGTH = 1024;

	// the rest of these values can be changed/tuned as needed...
	public static final int RESPONDER_SOCKET_TIMEOUT = 250;
	public static final int BROWSER_SOCKET_TIMEOUT = 250;
	public static final int BROWSER_QUERY_INTERVAL = 500;

}
