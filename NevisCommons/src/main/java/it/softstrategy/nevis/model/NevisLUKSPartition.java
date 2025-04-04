package it.softstrategy.nevis.model;

public class NevisLUKSPartition {
	
	private String luksName;
	private String mapperName;
	private String mountPoint;
	private String partitionName;//partitionName
	private boolean primary;

	
	public String getLuksName() {
		return luksName;
	}

	public void setLuksName(String luksName) {
		this.luksName = luksName;
	}

	public String getMapperName() {
		return mapperName;
	}

	public void setMapperName(String mapperName) {
		this.mapperName = mapperName;
	}

	public String getMountPoint() {
		return mountPoint;
	}

	public void setMountPoint(String mountPoint) {
		this.mountPoint = mountPoint;
	}


	public String getPartitionName() {
		return partitionName;
	}

	public void setPartitionName(String partitionName) {
		this.partitionName = partitionName;
	}

	public boolean isPrimary() {
		return primary;
	}

	public void setPrimary(boolean primary) {
		this.primary = primary;
	}

	@Override
	public String toString() {
		return "NevisLUKSPartition [luksName=" + luksName + ", mapperName=" + mapperName + ", mountPoint=" + mountPoint
				+ ", partitionName=" + partitionName + ", primary=" + primary + "]";
	}


	
	
	

}
