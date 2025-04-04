package it.softstrategy.nevis.util;

import java.util.Comparator;

public class NevisVideoSourceComparator implements Comparator<NevisVideoSource> {

	@Override
	public int compare(NevisVideoSource o1, NevisVideoSource o2) {
		int result; // = o1.getNevisCamera().getIpAddress().compareTo(o2.getNevisCamera().getIpAddress());
//		
//		if (result == 0) {
			result = o1.getId().compareTo(o2.getId());
//		}
		
		return result;
	}

}
