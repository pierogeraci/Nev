package it.softstrategy.nevis.model;

import java.util.SortedMap;

import org.simpleframework.xml.ElementMap;
import org.simpleframework.xml.Root;

@Root(name="LoadBalanceInfoArchive")
public class LoadBalanceInfoArchive {
	
	@ElementMap(entry="Entry", key="IPAddress", value="ProfileId", attribute=true, inline=true)
	private SortedMap<String, String> map;

	public SortedMap<String, String> getMap() {
		return map;
	}

	public void setMap(SortedMap<String, String> map) {
		this.map = map;
	}
	
	

}
