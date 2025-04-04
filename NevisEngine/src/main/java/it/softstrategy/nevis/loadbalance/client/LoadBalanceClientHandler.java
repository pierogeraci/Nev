/**
 * 
 */
package it.softstrategy.nevis.loadbalance.client;

import java.util.List;
import java.util.SortedMap;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import it.softstrategy.nevis.loadbalance.NevisLoadBalancer;
import it.softstrategy.nevis.util.LoadBalanceUtil;
import it.softstrategy.nevis.util.NevisVideoSource;

/**
 * @author lgalati
 *
 */
public class LoadBalanceClientHandler extends SimpleChannelInboundHandler<String> {
	
	public static final Logger LOG = LogManager.getLogger(LoadBalanceClientHandler.class.getName());
	
	
	private NevisLoadBalancer loadbalancer;
	
	public LoadBalanceClientHandler(NevisLoadBalancer loadbalancer) {
		this.loadbalancer = loadbalancer;
	}

	@Override
	protected void channelRead0(ChannelHandlerContext ctx, String msg) throws Exception {
		LOG.debug(String.format("Received message from Master Server [%s]",  msg));
		
		String response = null;
		
		if (msg.isEmpty()) {
			//che famo?
		} else if (msg.startsWith("MAP")) {
			//estrai la lista dal messaggio TCP
			String stringMap = msg.substring("MAP".length() + 1);
			SortedMap<NevisVideoSource,String> masterMap = LoadBalanceUtil.readMapFromString(stringMap);
			
			//aggiorno la mappa locale con quella del Master
			loadbalancer.merge(masterMap, Boolean.TRUE);
			
			List<NevisVideoSource> videoSourceNoProfile = loadbalancer.unbalancedVideoSources();
			if (videoSourceNoProfile.isEmpty()) {
				response = "OK";
			} else {
				response = "MERGE " + LoadBalanceUtil.convertListToString(videoSourceNoProfile);
			}
			
			ctx.channel().writeAndFlush(response + "\r\n");
			
		} else if ("END".equals(msg)) {
			LOG.debug("Load Balancing completed");
			ctx.channel().close().addListener(new ChannelFutureListener() {
				@Override
				public void operationComplete(ChannelFuture future) throws Exception {
					LOG.debug("Load Balancing Operation Ended");
					loadbalancer.completed();
				}
			});
		}
		
		
	}
	
	@Override
	public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
//		super.exceptionCaught(ctx, cause);
		
		LOG.error("Unexpected Exception!", cause);
		ctx.close();
	}

	

}
