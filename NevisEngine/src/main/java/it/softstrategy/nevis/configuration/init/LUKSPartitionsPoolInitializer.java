package it.softstrategy.nevis.configuration.init;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeoutException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.zeroturnaround.exec.InvalidExitValueException;
import org.zeroturnaround.exec.ProcessExecutor;
import org.zeroturnaround.exec.ProcessResult;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.enums.NevisAlarm;
import it.softstrategy.nevis.exceptions.RecordingStorageConfigurationException;
import it.softstrategy.nevis.exceptions.RecordingStorageMountDiskException;
import it.softstrategy.nevis.exceptions.RecordingStorageMountPoolException;
import it.softstrategy.nevis.model.NevisLUKSPartition;
import it.softstrategy.nevis.model.NevisLUKSPartitionsPool;
import it.softstrategy.nevis.util.LUKSPartitionUtils;

/**
 * @author lgalati
 *
 *
 *	Questo inizializzatore legge le configurazioni delle partizioni 
 */
public class LUKSPartitionsPoolInitializer implements RecordingsStorageInitBehavior {
	
	private static final Logger LOG = LogManager.getLogger(LUKSPartitionsPoolInitializer.class.getName());

	private final NevisConfiguration configuration;
	
	public LUKSPartitionsPoolInitializer() {
		configuration = new NevisConfigurationImpl();
	}
	
	@Override
	public void initRecordingsStorage() throws RecordingStorageConfigurationException, RecordingStorageMountPoolException {
		
//		ObjectMapper mapper = new ObjectMapper();
//		mapper.disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
		
		
		
		NevisLUKSPartitionsPool pool = null;
		try {
			File partitionsConfFile = new File(configuration.getPartitionsConfFilePath());
//			pool = mapper.readValue(partitionsConfFile, NevisLUKSPartitionsPool.class);
			pool = loadPool(partitionsConfFile);
		} catch (Exception e) {
			throw new RecordingStorageConfigurationException("Partitions pool configuration file corrupted or not found!!!", e);
		}
		
		if (pool.getPoolName() == null || pool.getPoolName().length() == 0
				|| pool.getType() == null || pool.getType().length() == 0
				|| pool.getPoolMountPoint() == null || pool.getPoolMountPoint().length() == 0
				|| pool.getPoolMode() == null || pool.getPoolMode().length() == 0) {
			throw new RecordingStorageConfigurationException("Bad Configuration - Partitions Pool informations empty or not specified!!!");
		}
		
		
		if (pool.getType().equals("single")) {
			LOG.info("Single Partition configuration detected");
			NevisLUKSPartition partition = pool.getPartitions().get(0);
			try {
				mountLUKSPartition(partition);
			} catch (RecordingStorageMountDiskException e) {
				LOG.fatal(NevisAlarm.DISKS.toString() + " - 1 - Mount Operation Error for partition " + partition.getPartitionName(), e);
				throw new RecordingStorageMountPoolException("Error while mounting Single Disk Storage.", e);
			}
		} else if (pool.getType().equals("multiple")) {
			//---------------------------------------------
			//		WORKING ON THE CRYPTED PARTITIONS
			//--------------------------------------------
			LOG.info("Multiple Partition configuration detected");
			
			List<String> mountPoints = new ArrayList<>();
			for (NevisLUKSPartition partition : pool.getPartitions()) {
				try {
					mountLUKSPartition(partition);
					mountPoints.add(partition.getMountPoint());
				} catch (Exception e) {
					LOG.fatal(NevisAlarm.DISKS.toString() + " - 1 - Mount Operation Error for partition " + partition.getPartitionName(), e);
				}
			}
			
			if (mountPoints.size() == 0) {
				throw new RecordingStorageMountPoolException("No disk was mounted. SKipping the Partition Pool mounting operation.");
			}
			
			
			//-----------------------------------------
			//		WORKINK ON THE POOL AND MARGERFS
			//-----------------------------------------
			//For security umount the pool
			ProcessResult pr = null;
			try {
				pr = new ProcessExecutor("/bin/bash", "-c", "umount " + pool.getPoolMountPoint()).readOutput(true).execute();
			} catch (Exception e) {
				LOG.error("Error while mounting Pool Partition.", e);
				// non lanciamo l'eccezione perché verrà lanciato dal prossimo comand bash
			}
			
			//Mounting the pool
			LOG.info("Mounting the Partition Pool");
			String partitionsMountPoints = String.join(":", mountPoints);
			String cmd = "mergerfs -o minfreespace=4G,defaults,allow_other,category.create=" + pool.getPoolMode() + ",fsname=" + pool.getPoolName() + ",nonempty "  + partitionsMountPoints + " " + pool.getPoolMountPoint();
			
//			ProcessResult pr = null;
			try {
				pr = new ProcessExecutor("/bin/bash", "-c", cmd).readOutput(true).execute();
			} catch (Exception e) {
				throw new RecordingStorageMountPoolException("Error while mounting Pool Partition.", e);
			}
			
			if (pr.getExitValue() != 0) {
				throw new RecordingStorageConfigurationException("Error while mounting Pool Partition: " + pr.outputUTF8());
			}
		} else {
			throw new RecordingStorageConfigurationException("Bad Configuration - Partitions Pool type " + pool.getType() + " non allowed");
		}
		
		//CHECK IF the "public" folder exists
		try {
			ProcessResult pr = new ProcessExecutor("/bin/bash", "-c", "ls /nevis | grep -F 'public'")
					.readOutput(true)./*exitValueNormal().*/execute();
			if (pr.outputUTF8().length() == 0 || !("public".equals(pr.outputUTF8().trim())) ) {
				LOG.info("NeVis IS work folder init...");
				new ProcessExecutor("/bin/bash", "-c", "mkdir -m 633 /nevis/public") // permette a www-data di creare cartelle all'interno
					.readOutput(true).exitValueNormal().execute();
				LOG.info("...done");
			}
		} catch (InvalidExitValueException | IOException | InterruptedException | TimeoutException e) {
			// TODO Auto-generated catch block
			LOG.error("Error while managing web work folder.", e);
			
		}


	}
	
	
	private void mountLUKSPartition(NevisLUKSPartition partition) throws RecordingStorageMountDiskException {
		
		if (partition.getPartitionName() == null || partition.getPartitionName().length() == 0
				|| partition.getMapperName() == null || partition.getMapperName().length() == 0
				|| partition.getMountPoint() == null || partition.getMountPoint().length() == 0) {
			throw new RecordingStorageMountDiskException("Error while opening Crypted Partition: partition configuration is not complete!");
		}
		
		try {
			String deviceName = partition.getMapperName().substring(partition.getMapperName().lastIndexOf("/") + 1);

			//Check for the presence of the crypted partition
			ProcessResult pr = new ProcessExecutor("/bin/bash", "-c", "lsblk -o NAME,TYPE,MOUNTPOINT | grep -F '" + deviceName + " crypt'"/* + partition.getMountPoint() +"'"*/).readOutput(true).execute();
			
			String lsblkResult = pr.outputUTF8();
			boolean isLuksDeviceOpen = lsblkResult.length() > 0;
			
			String mountPoint = null;
			
			//Se il disco criptato è chiuso, lo apro con cryptsetup
			if ( !isLuksDeviceOpen ) {
				String userToken = LUKSPartitionUtils.getUserToken();

				//Opening LUKS Crypted Partition
				LOG.debug("Opening crypted partition " + partition.getPartitionName());
				String cmd;

				cmd = "echo -n \'" + userToken + "\' | cryptsetup luksOpen " + partition.getPartitionName() + " " + deviceName;
				ProcessResult pr2 = new ProcessExecutor("/bin/bash", "-c", cmd).readOutput(true).execute();

				if (pr2.getExitValue() != 0) {
					throw new RecordingStorageMountDiskException("Error while opening Crypted Partition: " + pr2.outputUTF8());
				}
				
			} else {//Se è aperto verifico che ne sia stato fatto anche il mount
				int beginIndex = lsblkResult.indexOf("/");
				mountPoint = beginIndex > -1 ? lsblkResult.substring(beginIndex) : null;
			}
			
			
			if ( mountPoint == null || mountPoint.length() == 0)  {

				//Mount LUKS partition
				LOG.debug("Mounting crypted partition on point " + partition.getMountPoint());
				ProcessResult pr3 = new ProcessExecutor("/bin/bash", "-c", "mount " + partition.getMapperName() + " " + partition.getMountPoint()).readOutput(true).execute();
				if (pr3.getExitValue() != 0) {
					throw new RecordingStorageMountDiskException("Error while mounting Crypted Partition: " + pr3.outputUTF8());
				}

			} else {
				LOG.debug("Crypted Partition already mounted "  );
				LOG.debug("Mount Point: " + mountPoint  );
			}
		} catch (Exception e) {
			throw new RecordingStorageMountDiskException("Unexpected exception while mounting partition " + partition.getPartitionName(), e);
		}
	}
	
	private NevisLUKSPartitionsPool loadPool(File f) {
		ObjectMapper mapper = new ObjectMapper();
		
		NevisLUKSPartitionsPool pool = null;
		try {
			JsonNode root = mapper.readTree(f);
			pool = new NevisLUKSPartitionsPool();
			
			pool.setPoolMode(root.path("poolMode").asText());
			pool.setPoolMountPoint(root.path("poolMountPoint").asText());
			pool.setPoolName(root.path("poolName").asText());
			pool.setType(root.path("type").asText());
			
			List<NevisLUKSPartition> partitions = new ArrayList<>();
			JsonNode partitionsNode = root.path("partitions");
			
			if (partitionsNode.isArray()) {
				for (JsonNode partitionNode : partitionsNode) {
					NevisLUKSPartition luksPartition = new NevisLUKSPartition();
					
					luksPartition.setLuksName(partitionNode.path("luksName").asText());
					luksPartition.setMapperName(partitionNode.path("mapperName").asText());
					luksPartition.setMountPoint(partitionNode.path("mountPoint").asText());
					luksPartition.setPartitionName(partitionNode.path("partitionName").asText());
					luksPartition.setPrimary(partitionNode.path("primary").asBoolean());
					
					partitions.add(luksPartition);
				}
			}
			
			
			pool.setPartitions(partitions);
		} catch (IOException e) {
			LOG.error("Error while reading partition_conf.json", e);
			pool = null;
		}
		
		return pool;
	}
	
//	private void mountLUKSPartitionPool() {
//		
//	}

}
