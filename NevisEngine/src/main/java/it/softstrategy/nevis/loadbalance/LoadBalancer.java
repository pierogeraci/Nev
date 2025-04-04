package it.softstrategy.nevis.loadbalance;

import java.util.ArrayList;
import java.util.List;
import java.util.Map.Entry;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.concurrent.TimeUnit;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.google.common.eventbus.Subscribe;

import io.netty.bootstrap.Bootstrap;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import it.softstrategy.nevis.AppHelper;
import it.softstrategy.nevis.discovery.NevisServiceDescription;
import it.softstrategy.nevis.events.NVRDiscoveryEvent;
import it.softstrategy.nevis.events.RecordingConfigurationEvent;
import it.softstrategy.nevis.events.VideoSourceEvent;
import it.softstrategy.nevis.loadbalance.client.LoadBalanceClientInitializer;
import it.softstrategy.nevis.loadbalance.server.LoadBalanceServerInitializer;
import it.softstrategy.nevis.model.RecordingConfigurationEntry;
import it.softstrategy.nevis.model.UrlTemplateCameraProfile;
import it.softstrategy.nevis.util.IPUtil;
import it.softstrategy.nevis.util.NevisVideoSource;
import it.softstrategy.nevis.util.NevisVideoSourceComparator;

/**
 * @author lgalati
 *
 *
 * 
 */
public class LoadBalancer implements NevisLoadBalancer {
	
	public static final int PORT = 8023;
	
	private static final Logger LOG = LogManager.getLogger(LoadBalancer.class.getName());
	
//	private final NevisConfiguration configuration;
	
	
	//Per la comunicazione con gli altri NVR
	private EventLoopGroup workerGroup;
	private EventLoopGroup bossGroup;
	
	private List<NevisServiceDescription> otherNVRs;
	
	//La Mappa Bilanciata delle Sorgenti Video
	private SortedMap<NevisVideoSource, String> balancedMap;


	public LoadBalancer() {
//		configuration = new NevisConfigurationImpl();
		
		balancedMap =  null;
		
		otherNVRs = null;
	}
	
	public void initialize() {
		AppHelper.getInstance().getEventBus().register(this);
	}
	
	@Subscribe
	public synchronized void handleNVRDiscoveryEvent (NVRDiscoveryEvent event) {
		
		boolean first = otherNVRs == null; //E' la prima volta che inizializziamo otheNVRs quindi la prima volta che l'evento arriva
		otherNVRs = event.getDescriptors();
		
		if (iAmTheMaster()) {
			LOG.debug("I am The Master");
			try {
				startServer();
			} catch (InterruptedException e) {
				LOG.error("Unexpected Exception from Load Balancer Server", e);
				//TODO: SNMP?
			}
		} else {
			LOG.debug("I am not The Master");
			try {
				if (balancedMap != null) {
					askForBalancedMap(first);
				}
				
			} catch (InterruptedException e) {
				LOG.error("Unexpected InterruptedException", e);
			}
			
		}
	}
	
	@Subscribe
	public synchronized void handleVideoSourceEvent(VideoSourceEvent event) {
		//Avvia un sessione di bilanciamento
		LOG.debug("Ricevuta segnalazione di nuove Sorgenti Video!");
		boolean first = false;
		
		if (balancedMap == null) { 
			//First "VideoSourceEvent" event since application startup
			first = true;
			balancedMap = new TreeMap<>(new NevisVideoSourceComparator());
		}
		
		if (iAmTheMaster()) {
			//Se sono il master eseguo il bilanciamento
			balance(event.getVideoSources());
			sendNotification();
		} else {
			//Se non sono il master, lo contatto per avere la
			//lista bilanciata
			try {
				askForBalancedMap(first);
			} catch (InterruptedException e) {
				LOG.error("Unexpected InterruptedException", e);
			}
		}	
	}
	
	
	@Override
	public synchronized boolean balance(List<NevisVideoSource> newVideoSources) {
		boolean result = false;
		
		for(NevisVideoSource newVideoSource : newVideoSources) {
			if (!balancedMap.containsKey(newVideoSource)) {
				String profileSelected = balancingStatus() < 1 ? "HD" : "LD";
				balancedMap.put(newVideoSource, profileSelected);
				result = Boolean.TRUE;
			}
		}
		
		return result;
	}

	
	@Override
	public synchronized void merge(SortedMap<NevisVideoSource, String> otherMap, boolean invert) {
		
		for(Entry<NevisVideoSource, String> entry : otherMap.entrySet()) {
			NevisVideoSource videoSource = entry.getKey();
			String profileId = entry.getValue();
			
			
			String newProfileId;
			if (invert) {
				newProfileId = profileId.equals("HD") ? "LD" : "HD";
			} else {
				newProfileId = profileId;
			}
			
			if (balancedMap.containsKey(videoSource)) {
				balancedMap.replace(videoSource, newProfileId);
			} else {
				balancedMap.put(videoSource, newProfileId);
			}
			
		}
		
	}

	
	@Override
	public synchronized SortedMap<NevisVideoSource, String> getBalancedMap() {
		return new TreeMap<>(balancedMap);
	}
	
	
	private synchronized int balancingStatus() {
		int hdCounter = 0;
		int ldCounter = 0;
		for (String profileID : balancedMap.values()) {
			if (profileID != null) {
				if (profileID.equals("HD")) {
					hdCounter++;
				} else if (profileID.equals("LD")) {
					ldCounter++;
				}
			}
		}
//		LOG.debug("balancingStatus : hdCounter : " + hdCounter + " ldCounter : "+ ldCounter + " result : " + (hdCounter - ldCounter) );
		return hdCounter - ldCounter;
	}
	
	private boolean iAmTheMaster() {
		if (otherNVRs != null && !otherNVRs.isEmpty()) {
			String localIpAddress = IPUtil.getMyIpAddress();
			NevisServiceDescription otherNode = otherNVRs.get(0);
			String otherIpAddress = otherNode.getAddress().getHostAddress();
			return otherIpAddress.compareTo(localIpAddress) > 0;
		}
		
		//Se non ci sono altri NVR sono io il Master
		return true;
	}
	
	private void startServer() throws InterruptedException {
		bossGroup = new NioEventLoopGroup(1);
		workerGroup = new NioEventLoopGroup();
		
//		try {
			ServerBootstrap b = new ServerBootstrap();
			
			b.group(bossGroup, workerGroup)
				.channel(NioServerSocketChannel.class)
				.option(ChannelOption.SO_BACKLOG, 1000)
//				.handler(new LoggingHandler(LogLevel.INFO))
				.childHandler(new LoadBalanceServerInitializer(this));
			
			b.bind(PORT).sync()/*.channel().closeFuture().sync()*/;
//		} 
//		finally {
//			bossGroup.shutdownGracefully();
//			workerGroup.shutdownGracefully();
//		}
	}
	
	
	private void askForBalancedMap(boolean first) throws InterruptedException {
		LOG.debug("Asking for the balancep VideoSources MAP");
		
		if (first) {
			TimeUnit.MILLISECONDS.sleep(5000);
		}
		
		//Avviamo il client
		workerGroup = new NioEventLoopGroup();
		
		
			Bootstrap b = new Bootstrap();
			b.group(workerGroup)
				.channel(NioSocketChannel.class)
				.handler(new LoadBalanceClientInitializer(this));
			
			NevisServiceDescription masterAddress = otherNVRs.get(0);
			String ipAddress = masterAddress.getAddress().getHostAddress();
			
			//Start the connection attempt.
			b.connect(ipAddress, PORT).sync();
	}
	
	private void stop() {
		if (bossGroup != null) {
			bossGroup.shutdownGracefully();
		}
		if (workerGroup != null) {
			workerGroup.shutdownGracefully();
			workerGroup = null;
		}
	}

	@Override
	public synchronized boolean add(List<NevisVideoSource> videoSources) {
		boolean result = Boolean.FALSE;
		
		for(NevisVideoSource newVideoSource : videoSources) {
			if ( !balancedMap.containsKey(newVideoSource) ) {
				balancedMap.put(newVideoSource, null);
				result = Boolean.TRUE;
			}
		}
		
		return result;
	}

	@Override
	public List<NevisVideoSource> unbalancedVideoSources() {
		List<NevisVideoSource> result = new ArrayList<>();
		
		for (NevisVideoSource videoSource : balancedMap.keySet()) {
			if (balancedMap.get(videoSource) == null) {
				result.add(videoSource);
			}
		}
		
		return result;
	}

	@Override
	public synchronized void completed() {
		
		if (!iAmTheMaster()) {
			stop();
		}
		
		sendNotification();		
	}
	
	private void sendNotification() {
		LOG.info("SENDING EVENT TO THREAD MANAGER");
		RecordingConfigurationEvent event = 
				new RecordingConfigurationEvent(RecordingConfigurationEvent.Type.UPDATE, toList());
		AppHelper.getInstance().getEventBus().post(event);
	}
	
	
	//TODO: move this method in an utility class
	private synchronized List<RecordingConfigurationEntry> toList() {
		List<RecordingConfigurationEntry> result = new  ArrayList<>();
		
		
		for (Entry<NevisVideoSource, String> ent : balancedMap.entrySet()) {
			NevisVideoSource videoSource = ent.getKey();
			String encoder = ent.getValue();
			
			RecordingConfigurationEntry rce = new RecordingConfigurationEntry();
			rce.setAudio(false);
			rce.setDepth(100);
			rce.setDescription("");
			rce.setEncoder(encoder);
//			int id = Integer.parseInt(videoSource.getTemplate().getId());
//			rce.setId(id);
			rce.setIpAddress(videoSource.getNevisCamera().getIpAddress());
			rce.setMacAddress(videoSource.getNevisCamera().getMacAddress());
			rce.setModel(videoSource.getNevisCamera().getModel());
			rce.setPassword("");
			rce.setSensorId(videoSource.getTemplate().getSensorId());
			String url = "";
			for (UrlTemplateCameraProfile profile : videoSource.getTemplate().getProfiles()) {
				if (encoder.equals(profile.getId())) {
					String template = profile.getUrlTemplate();
					url = template.replace("${IP_ADDRESS}", videoSource.getNevisCamera().getIpAddress());
				}
			}
			rce.setUrl(url);
			rce.setUsername("");
			rce.setVendor(videoSource.getNevisCamera().getVendor());
			rce.setVideoSourceId(videoSource.getId());
			
			result.add(rce);
		}
		
		return result;
		
	}

}
