
package it.softstrategy.nevis.loadbalance;

import java.util.List;
import java.util.SortedMap;

import it.softstrategy.nevis.util.NevisVideoSource;

/**
 * @author lgalati
 *
 */
public interface NevisLoadBalancer {

	boolean add(List<NevisVideoSource> videoSources);

	boolean balance(List<NevisVideoSource> newVideoSources);

	void merge(SortedMap<NevisVideoSource, String> otherMap, boolean invert);

	SortedMap<NevisVideoSource, String> getBalancedMap();

	List<NevisVideoSource> unbalancedVideoSources();
	
	void completed();
	 

}
