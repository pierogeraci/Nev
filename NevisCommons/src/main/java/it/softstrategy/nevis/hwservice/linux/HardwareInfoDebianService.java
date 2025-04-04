package it.softstrategy.nevis.hwservice.linux;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeoutException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.zeroturnaround.exec.InvalidExitValueException;
import org.zeroturnaround.exec.ProcessExecutor;
import org.zeroturnaround.exec.ProcessResult;

import it.softstrategy.nevis.hwservice.HardwareConstants;
import it.softstrategy.nevis.hwservice.HardwareInfoService;
//import it.softstrategy.nevis.license.util.NevisConstants;

public class HardwareInfoDebianService implements HardwareInfoService {

	@Override
	public String getSystemUuid() {
		String systemUuid = null;
		try {
			ProcessResult pr = new ProcessExecutor("/bin/bash", "-c", "dmidecode -s system-uuid").readOutput(true)
					.execute();
			systemUuid = pr.outputUTF8();
			if (systemUuid != null && systemUuid.length() > 0) {
				systemUuid = systemUuid.trim();
				systemUuid = systemUuid.replace(' ', Character.MIN_VALUE);
				systemUuid = systemUuid.replace('-', Character.MIN_VALUE);
			}
		} catch (InvalidExitValueException | IOException | InterruptedException | TimeoutException e) {

		}
		return systemUuid;
	}

	@Override
	public String getSystemSerialNumber() {
		String systemSerialNumber = null;
		try {
			ProcessResult pr = new ProcessExecutor("/bin/bash", "-c", "dmidecode -s system-serial-number")
					.readOutput(true).execute();
			systemSerialNumber = pr.outputUTF8();
			if (systemSerialNumber != null && systemSerialNumber.length() > 0
					&& HardwareConstants.TO_BE_FILLED_BY_OEM.equalsIgnoreCase(systemSerialNumber)) {
				systemSerialNumber = systemSerialNumber.trim();
				systemSerialNumber = systemSerialNumber.replace(' ', Character.MIN_VALUE);
				systemSerialNumber = systemSerialNumber.replace('-', Character.MIN_VALUE);
			}
		} catch (InvalidExitValueException | IOException | InterruptedException | TimeoutException e) {

		}
		return systemSerialNumber;
	}

	@Override
	public String getMotherBoardSerialNumber() {
		String motherBoardSerialNumber = null;
		try {
			ProcessResult pr = new ProcessExecutor("/bin/bash", "-c", "dmidecode -s baseboard-serial-number")
					.readOutput(true).execute();
			motherBoardSerialNumber = pr.outputUTF8();
			if (motherBoardSerialNumber != null && motherBoardSerialNumber.length() > 0
					&& HardwareConstants.TO_BE_FILLED_BY_OEM.equalsIgnoreCase(motherBoardSerialNumber)) {
				motherBoardSerialNumber = motherBoardSerialNumber.trim();
				motherBoardSerialNumber = motherBoardSerialNumber.replace(' ', Character.MIN_VALUE);
				motherBoardSerialNumber = motherBoardSerialNumber.replace('-', Character.MIN_VALUE);
			}
		} catch (InvalidExitValueException | IOException | InterruptedException | TimeoutException e) {

		}
		return motherBoardSerialNumber;
	}

	@Override
	public String getMotherBoardAssetTag() {
		String motherBoardAssetTag = null;
		try {
			ProcessResult pr = new ProcessExecutor("/bin/bash", "-c", "dmidecode -s baseboard-asset-tag")
					.readOutput(true).execute();
			motherBoardAssetTag = pr.outputUTF8();
			if (motherBoardAssetTag != null && motherBoardAssetTag.length() > 0
					&& HardwareConstants.TO_BE_FILLED_BY_OEM.equalsIgnoreCase(motherBoardAssetTag)) {
				motherBoardAssetTag = motherBoardAssetTag.trim();
				motherBoardAssetTag = motherBoardAssetTag.replace(' ', Character.MIN_VALUE);
				motherBoardAssetTag = motherBoardAssetTag.replace('-', Character.MIN_VALUE);
			}
		} catch (InvalidExitValueException | IOException | InterruptedException | TimeoutException e) {

		}
		return motherBoardAssetTag;
	}

	@Override
	public List<String> getMacHardwareAddresses() {
		List<String> addresses = new ArrayList<>();

		// Read all available device names
		List<String> devices = new ArrayList<>();
		Pattern pattern = Pattern.compile("^ *(.*):");
		try (FileReader reader = new FileReader("/proc/net/dev")) {
			BufferedReader in = new BufferedReader(reader);
			String line = null;
			while ((line = in.readLine()) != null) {
				Matcher m = pattern.matcher(line);
				if (m.find()) {
					devices.add(m.group(1));
				}
			}
		} catch (IOException e) {
			System.err.println("Unexpected exception while reading system info");
		}

		// read the hardware address for each device
		for (String device : devices) {
			try {
				NetworkInterface iface = NetworkInterface.getByName(device);
				boolean isLoopback = iface != null && iface.isLoopback();
				if (!isLoopback) {
					try (FileReader reader = new FileReader("/sys/class/net/" + device + "/address")) {
						BufferedReader in = new BufferedReader(reader);
						String addr = in.readLine();
						addr = addr.replaceAll(":", "");
						addresses.add(addr);
					} catch (IOException e) {
						System.err.println("Unexpected exception while reading system info");
					}
				}
			} catch (SocketException e) {
				// Do nothing
			}
		}

		return addresses;
	}

}
