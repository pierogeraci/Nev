package it.softstrategy.nevis.model;

import java.util.List;

import org.simpleframework.xml.ElementList;
import org.simpleframework.xml.Root;

@Root(name="SlotsArchive")
public class SlotsArchive {
	
	
	@ElementList(inline=true/*,required=false*/)
	private List<SlotsArchiveEntry> archive;
	

	public List<SlotsArchiveEntry> getArchive() {
		return archive;
	}

	public void setArchive(List<SlotsArchiveEntry> archive) {
		this.archive = archive;
	}
	
	
	

}
