/**
 * 
 */
package it.softstrategy.nevis.configuration.init;

import java.io.File;
import java.util.Date;
import java.util.List;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.filefilter.FileFilterUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;

/**
 * @author lgalati
 * 
 * Linux File System Work Folder Initializer
 *
 */
public class LFSWorkFolderInitializer implements WorkFolderInitBehavior {
	
	private static final Logger LOG = LogManager.getLogger(LFSWorkFolderInitializer.class.getName());
	
	
	private final NevisConfiguration configuration;
	
	

	public LFSWorkFolderInitializer() {
		configuration = new NevisConfigurationImpl();
	}



	@Override
	public void cleanWorkingFolder() throws Exception {
		LOG.debug("Starting Work Folder Management...");
		
		String workFolderPath = configuration.getWorkFolder();
		String workFolderPathHistory = configuration.getWorkHistoryFolder();
		LOG.debug("Moving files WORK FOLDER: " + workFolderPath + " to History Folder: " + workFolderPathHistory);

		File srcDirectory = new File(workFolderPath);
		File destDirectory = new File(workFolderPathHistory);
		
//		File recList = new File(configuration.getRecordingsStorageFilePath());
//		File uptimeFile = new File (configuration.getUpTimeServerFilePath());
		
		File sdFile = new File(configuration.getServerDiscoveryStorageFilePath());
		File odFile = new File(configuration.getOnvifDiscoveryStorageFilePath());
		
		@SuppressWarnings("unchecked")
		List<File> files = (List<File>) FileUtils.listFiles(srcDirectory, FileFilterUtils.fileFileFilter(), null);
		Date now = new Date();
		for (File file : files) {
			LOG.info("Detected file :" + file.getName() );
			if (file.getName().equals( sdFile.getName() )
					|| file.getName().equals(odFile.getName())) {

				String newFileName = FilenameUtils.getBaseName(file.getName()) 
						+ "_" + now.getTime()
						+ "." + FilenameUtils.getExtension(file.getName());
				File newFile = new File(newFileName);
				if (file.renameTo(newFile)) {
					LOG.debug("File renamed to: " + newFile.getName());
					FileUtils.moveFileToDirectory(newFile, destDirectory, Boolean.TRUE);
					LOG.debug("File " + newFile.getName() + " moved to " + workFolderPathHistory);
				} else {
					FileUtils.moveFileToDirectory(file, destDirectory, Boolean.TRUE);
					LOG.debug("File " + file.getName() + " moved to " + workFolderPathHistory);
				}	
			}
		}
		
		LOG.debug("Work Folder Management completed.");
	}

}
