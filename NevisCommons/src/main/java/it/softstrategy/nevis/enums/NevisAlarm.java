package it.softstrategy.nevis.enums;

/**
 * @author lgalati
 *
 */
public enum NevisAlarm {
	
	ARCHIVE("archive"),
	DISKS("disks"),
	DISKS_CONFIGURATION("confDisks"),
	LICENSE("license"),
	ENGINE("nevisEngine");
	
	
	private String jsonKeyName;

	private NevisAlarm(String jsonKeyName) {
		this.jsonKeyName = jsonKeyName;
	}
	
	
	public String toString() {
		return this.jsonKeyName;
	}
	
	

}
