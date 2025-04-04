/**
 * 
 */
package it.softstrategy.nevis.loadbalance.server;

import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.socket.SocketChannel;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.Delimiters;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import it.softstrategy.nevis.loadbalance.NevisLoadBalancer;

/**
 * @author lgalati
 *
 */
public class LoadBalanceServerInitializer extends ChannelInitializer<SocketChannel> {

	private static final StringDecoder DECODER = new StringDecoder();
	private static final StringEncoder ENCODER = new StringEncoder();
	
	private NevisLoadBalancer loadbalancer;
	
	
	public LoadBalanceServerInitializer(NevisLoadBalancer loadbalancer) {
		this.loadbalancer = loadbalancer;
	}

	
	@Override
	protected void initChannel(SocketChannel ch) throws Exception {
		ChannelPipeline pipeline = ch.pipeline();
		
		pipeline.addLast(new DelimiterBasedFrameDecoder(8192, Delimiters.lineDelimiter()));
		pipeline.addLast(DECODER);
		pipeline.addLast(ENCODER);
		pipeline.addLast(new LoadBalanceServerHandler(loadbalancer));
	}

}
