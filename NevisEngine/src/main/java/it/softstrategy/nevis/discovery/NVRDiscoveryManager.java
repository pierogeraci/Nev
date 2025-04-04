
package it.softstrategy.nevis.discovery;

import java.net.InetAddress;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.AppHelper;
import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.events.NVRDiscoveryEvent;
import it.softstrategy.nevis.loadbalance.LoadBalancer;
import it.softstrategy.nevis.util.IPUtil;

/**
 * @author lgalati
 *
 */
public class NVRDiscoveryManager implements NevisServiceBrowserListener, Runnable/*, Subject*/ {

	private static final Logger LOG = LogManager.getLogger(NVRDiscoveryManager.class.getName());
	
	public static final String SERVICE_NAME = "NevisDiscoveryService";
	
	
	private final NevisConfiguration configuration;
	
	//Per la comunicazione sulla rete
	private NevisServiceResponder responder;
	private NevisServiceBrowser browser;
	
	private ScheduledThreadPoolExecutor executor;
	
	//Cache con la lista degli altri server
	private Vector<NevisServiceDescription> descriptors;
	
	
	private final Object DESC_MONITOR = new Object();

	

	public NVRDiscoveryManager() {
		configuration = new NevisConfigurationImpl();
		descriptors = new Vector<NevisServiceDescription>();
		executor = (ScheduledThreadPoolExecutor) Executors.newScheduledThreadPool(1);
	}
	
	
	public void start() {
		
		boolean repeteable = false;
		
		if (repeteable) {
			//TODO: finire di implementare
//			long period = 10; //TODO: importare dal file di conf
//			executor.scheduleAtFixedRate(this, 0L, period , TimeUnit.MILLISECONDS);
		} else {
			//One Shot
			executor.schedule(this, 0L, TimeUnit.MILLISECONDS);
		}
	} 
	
	public void stop () {
		
		executor.shutdown();
		
		try {
			executor.awaitTermination(10L, TimeUnit.SECONDS);
		} catch (InterruptedException e) {
			LOG.error("ScheduledThreadPoolExecutor Shutdown is getting too much time...", e);
		}
	}
	
	
	public boolean isWorking() {
		return !executor.isTerminated();
	}
	

	@Override
	public void run() {

		try {		
//			InetAddress localAddr = InetAddress.getLocalHost();
			InetAddress localAddr = IPUtil.getMyInetAddress();

			NevisServiceDescription descriptor = new NevisServiceDescription();
			String serviceInstanceName = SERVICE_NAME + "_" + localAddr.getHostAddress();
			descriptor.setAddress(localAddr);
			descriptor.setPort(LoadBalancer.PORT);
			descriptor.setInstanceName(serviceInstanceName);
			LOG.debug("Service details: " + descriptor.toString());

			responder = new NevisServiceResponder(SERVICE_NAME);
			responder.setDescriptor(descriptor);
			responder.addShutdownHandler();
			responder.startResponder();

//			descriptors = new Vector<NevisServiceDescription>();
			browser = new NevisServiceBrowser();
			browser.addServiceBrowserListener(this);
			browser.setServiceName(SERVICE_NAME);
			browser.startListen();
			browser.startLookup();
			Long duration = configuration.getServerDiscoveryDuration();
			LOG.debug("Browser started. Will search for " + duration +" secs.");
			try {
				Thread.sleep(duration * 1000);
			}
			catch (InterruptedException ie) {
				// ignore
			}
			browser.stopLookup();
			browser.stopListen();
			responder.stopResponder();
		} /*catch (UnknownHostException e) {
			LOG.error("Error", e);
		}*/ finally {
			
			sendNotification();
			
		}

	}
	
	
	public List<NevisServiceDescription> getDescriptors() {
		List<NevisServiceDescription> nodesCopy;
		
		synchronized (DESC_MONITOR) {
			nodesCopy = new ArrayList<>(descriptors);
		}
		
		return nodesCopy;
	}

	
	@Override
	public void serviceReply(NevisServiceDescription descriptor) {
		int pos = descriptors.indexOf(descriptor);
		
		synchronized (DESC_MONITOR) {//Forse non serve...solo un thread accede a questa
			if (pos > -1) {
				descriptors.removeElementAt(pos);
			}
			descriptors.add(descriptor);
		}
	}
	
	
	private void sendNotification() {
		LOG.debug(getDescriptors().isEmpty() ? "Nessun NVR trovato" : getDescriptors());
		NVRDiscoveryEvent event = new NVRDiscoveryEvent(getDescriptors());
		AppHelper.getInstance().getEventBus().post(event);
	}
	



}
