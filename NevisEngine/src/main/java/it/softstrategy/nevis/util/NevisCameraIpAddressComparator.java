package it.softstrategy.nevis.util;

import java.util.Comparator;

import it.softstrategy.nevis.model.NevisCamera;

public class NevisCameraIpAddressComparator implements Comparator<NevisCamera> {

	@Override
	public int compare(NevisCamera nc1, NevisCamera nc2) {
		
		return nc1.getIpAddress().compareTo(nc2.getIpAddress());
		
	}

}
