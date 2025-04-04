/**
 * 
 */
package it.softstrategy.nevis.loadbalance;

import java.util.ArrayList;
import java.util.List;
import java.util.Map.Entry;
import java.util.SortedMap;
import java.util.TreeMap;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.util.NevisVideoSource;
import it.softstrategy.nevis.util.NevisVideoSourceComparator;

/**
 * @author lgalati
 *
 *
 *	DEPRECATO
 */
class BalancedMap {
	
	private static final Logger LOG = LogManager.getLogger(BalancedMap.class.getName());
	
//	private SortedMap<NevisCamera, String> _balancedMap;
	private SortedMap<NevisVideoSource, String> _balancedMap;

	public BalancedMap() {
//		_balancedMap = new TreeMap<>(new NevisCameraIpAddressComparator());
		_balancedMap = new TreeMap<>(new NevisVideoSourceComparator());
		//TODO: si potrebbe prepopolare la mappa bilanciata con informazioni recuperate dallo "storico" (ultimo file rec_list.xml)
	}
	
	
	public synchronized boolean add(/*List<NevisCamera> cameras*/List<NevisVideoSource> videoSources) {
		boolean result = Boolean.FALSE;
		
		for(NevisVideoSource newVideoSource : videoSources) {
			if (! _balancedMap.containsKey(newVideoSource)) {
				_balancedMap.put(newVideoSource, null);
				result = Boolean.TRUE;
			}
		}
		
		return result;
	}
	
	
	/**
	 * @param otherMap
	 * @return
	 */
	public synchronized void update(/*SortedMap<NevisCamera, String>*/SortedMap<NevisVideoSource, String> otherMap, boolean invert) {
		
		for(Entry<NevisVideoSource, String> entry : otherMap.entrySet()) {
			NevisVideoSource videoSource = entry.getKey();
			String profileId = entry.getValue();
			
			
			String newProfileId;
			if (invert) {
				newProfileId = profileId.equals("HD") ? "LD" : "HD";
			} else {
				newProfileId = profileId;
			}
			
			if (_balancedMap.containsKey(videoSource)) {
				_balancedMap.replace(videoSource, newProfileId);
			} else {
				_balancedMap.put(videoSource, newProfileId);
			}
			
		}
	}


	//TODO: controllare sia giusto
	public synchronized boolean contains(/*NevisCamera camera*/NevisVideoSource videoSource) {			
		for (NevisVideoSource currVideoSource : _balancedMap.keySet()) {
			String currIpAddress = currVideoSource.getNevisCamera().getIpAddress();
			
			if (currIpAddress != null && !currIpAddress.isEmpty() && currIpAddress.equals(videoSource.getNevisCamera().getIpAddress())
					&& currVideoSource.getId() == videoSource.getId() 
					) {
				return true;
			}
		}
		
		return false;
	}
	
	
	/**
	 * 
	 * 
	 * @param newCameras
	 * @return true if the at least one camera has been added. false otherwise 
	 * (all the camera already in the list) 
	 */
	public synchronized boolean balance(/*List<NevisCamera> newCameras*/List<NevisVideoSource> newVideoSources) {
		boolean result = Boolean.FALSE;
		
		for(NevisVideoSource newVideoSource : newVideoSources) {
			if (!_balancedMap.containsKey(newVideoSource)) {
				String profileSelected = balancingStatus() < 1 ? "HD" : "LD";
				_balancedMap.put(newVideoSource, profileSelected);
				result = Boolean.TRUE;
			}
		}
		
		return result;
	}
	
	public synchronized /*List<NevisCamera>*/ List<NevisVideoSource> unbalancedVideoSources() {
		List<NevisVideoSource> result = new ArrayList<>();
		
		for (NevisVideoSource videoSource : _balancedMap.keySet()) {
			if (_balancedMap.get(videoSource) == null) {
				result.add(videoSource);
			}
		}
		
		return result;
	}
	

	/**
	 * Costruisce una copia della mappa bilanciata e la registituisce al chiamante
	 * @return una copia della mappa bilanciata
	 */
	public synchronized /*SortedMap<NevisCamera, String>*/ SortedMap<NevisVideoSource, String> copyToMap() {
//		SortedMap<NevisCamera, String> copy = new TreeMap<>(new NevisCameraIpAddressComparator());
		SortedMap<NevisVideoSource, String> copy = new TreeMap<>(new NevisVideoSourceComparator());
		copy.putAll(_balancedMap);
		return copy;
	}
	
	/*
	 * Utility method: return the difference betwenn HD and LD cameras
	 */
	private int balancingStatus() {
		int hdCounter = 0;
		int ldCounter = 0;
		for (String profileID : _balancedMap.values()) {
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

}