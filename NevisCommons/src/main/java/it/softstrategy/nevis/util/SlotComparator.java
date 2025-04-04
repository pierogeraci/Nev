package it.softstrategy.nevis.util;

import java.util.Comparator;

import it.softstrategy.nevis.model.Slot;

/**
 * @author lgalati
 *
 */
public class SlotComparator implements Comparator<Slot> {

	
	@Override
	public int compare(Slot s1, Slot s2) {
		
		int cmp;
		if (s1.getId() > s2.getId())
		   cmp = +1;
		else if (s1.getId() < s2.getId())
		   cmp = -1;
		else
		   cmp = 0;
		
		return cmp;
	}

}
