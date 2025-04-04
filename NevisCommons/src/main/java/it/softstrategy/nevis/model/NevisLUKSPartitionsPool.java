package it.softstrategy.nevis.model;

import java.util.List;

public class NevisLUKSPartitionsPool {
	
	private String poolMode; // poolMode
	private String poolMountPoint; //poolMountPoint
	private String poolName; // poolName
	private String type;
	private List<NevisLUKSPartition> partitions;
	
	
	public String getPoolMode() {
		return poolMode;
	}
	
	public void setPoolMode(String poolMode) {
		this.poolMode = poolMode;
	}
	
	
	public String getPoolMountPoint() {
		return poolMountPoint;
	}
	
	public void setPoolMountPoint(String poolMountPoint) {
		this.poolMountPoint = poolMountPoint;
	}
	
	
	public String getPoolName() {
		return poolName;
	}
	
	public void setPoolName(String poolName) {
		this.poolName = poolName;
	}
	
	
	public String getType() {
		return type;
	}
	
	public void setType(String type) {
		this.type = type;
	}
	
	
	public List<NevisLUKSPartition> getPartitions() {
		return partitions;
	}
	
	public void setPartitions(List<NevisLUKSPartition> partitions) {
		this.partitions = partitions;
	}

	@Override
	public String toString() {
		return "NevisLUKSPartitionsPool [poolMode=" + poolMode + ", poolMountPoint=" + poolMountPoint + ", poolName="
				+ poolName + ", type=" + type + ", partitions=" + partitions + "]";
	}
	
	

	
	
	
}
