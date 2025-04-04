package it.softstrategy.nevis.hwservice.mock;

import java.util.List;

import it.softstrategy.nevis.hwservice.HardwareInfoService;

public class HardwareInfoMockService implements HardwareInfoService {

	
	@Override
	public String getSystemUuid() {
		return "03000200-0400-0500-0006-000700080009";
	}

	@Override
	public String getSystemSerialNumber() {
		return "To Be Filled By O.E.M.";
	}

	@Override
	public String getMotherBoardSerialNumber() {
		return "To Be Filled By O.E.M.";
	}

	@Override
	public String getMotherBoardAssetTag() {
		return "To Be Filled By O.E.M.";
	}

	@Override
	public List<String> getMacHardwareAddresses() {
		
		//TODO: completare
		return null;
	}

}
