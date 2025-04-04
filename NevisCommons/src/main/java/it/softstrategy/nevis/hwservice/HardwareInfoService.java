package it.softstrategy.nevis.hwservice;

import java.util.List;

public interface HardwareInfoService {
	
	String getSystemUuid();
	
	String getSystemSerialNumber();
	
	String getMotherBoardSerialNumber();
	
	String getMotherBoardAssetTag();
	
	List<String> getMacHardwareAddresses();

}
