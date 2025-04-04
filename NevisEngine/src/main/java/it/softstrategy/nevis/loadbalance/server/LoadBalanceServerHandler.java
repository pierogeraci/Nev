package it.softstrategy.nevis.loadbalance.server;

import java.util.List;

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
 *
 */
public class LoadBalanceServerHandler extends SimpleChannelInboundHandler<String> {
	
	public static final Logger LOG = LogManager.getLogger(LoadBalanceServerHandler.class.getName());
	
	
	private NevisLoadBalancer loadbalancer;
	
	
	public LoadBalanceServerHandler(NevisLoadBalancer loadbalancer) {
		this.loadbalancer = loadbalancer;
	}

	
//	@Override
//	public void channelInactive(ChannelHandlerContext ctx) throws Exception {
//		// TODO Auto-generated method stub
//		super.channelInactive(ctx);
//	}


	@Override
	public void channelActive(ChannelHandlerContext ctx) throws Exception {
//		super.channelActive(ctx);
		
		LOG.debug("Connection activated");
		//Inviare la via configurazione
		String stringMap = LoadBalanceUtil.convertMapToString(loadbalancer.getBalancedMap());
		ctx.writeAndFlush("MAP " + stringMap + "\r\n");
	}

	@Override
	protected void channelRead0(ChannelHandlerContext ctx, String msg) throws Exception {
		LOG.debug(String.format("Received message from Client [%s]",  msg));
		// Generazione di una risposta.
		String response = "";
		boolean close = false;
		
		if (msg.isEmpty()) {
			response = "";//che famo?
		} else if ("OK".equals (msg.toUpperCase())) {
			response = "END";//Mandare messaggio finale?
			close = true;
		} else if (msg.startsWith("MAP")) {
			 //qui chiamare il Load Balancer
			
			//estrazione della lista dello slave  
			String stringList = msg.substring("MAP".length() + 1);
			List<NevisVideoSource> slaveList = LoadBalanceUtil.readListFromString(stringList);
			
			boolean mapUpdated = loadbalancer.balance(slaveList);
			
			if (mapUpdated) {
				LOG.debug("Map update after Slave response");
			} else {
				LOG.warn("Map NOT update after Slave response");
			}
			
			response =  "MAP " + LoadBalanceUtil.convertMapToString(loadbalancer.getBalancedMap());
		}
		
		
		LOG.debug("Sending response to client [" + response + "]");
		ChannelFuture future = ctx.write(response + "\r\n");
		
		if (close) {
			future.addListener(ChannelFutureListener.CLOSE);
			loadbalancer.completed();
		}
	}
	
	

	@Override
	public void channelReadComplete(ChannelHandlerContext ctx) throws Exception {
//		super.channelReadComplete(ctx);
		ctx.flush();
	}

	@Override
	public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
//		super.exceptionCaught(ctx, cause);
		
		LOG.error("Unexpected Exception!", cause);
		ctx.close();
	}

	

}
