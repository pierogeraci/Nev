package it.softstrategy.nevis.model;

import java.util.List;

import org.simpleframework.xml.ElementList;
import org.simpleframework.xml.Root;

@Root(name="Cams")
public class RecordingsList {

	@ElementList(inline=true)
	private List<Recording> recordings;

	public List<Recording> getRecordings() {
		return recordings;
	}

	public void setRecordings(List<Recording> recordings) {
		this.recordings = recordings;
	}


	@Override
	public String toString() {
		return "RecordingsList [recordings= " + recordings + "]";
	}
	
	
	
	
}
