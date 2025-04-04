package it.softstrategy.nevis.externalconf;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardWatchEventKinds;
import java.nio.file.WatchEvent;
import java.nio.file.WatchKey;
import java.nio.file.WatchService;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.util.FileWatcherListener;

/**
 * @author lgalati
 *
 */
public class FileWatcher implements Runnable {
	
	private final static Logger LOG = LogManager.getLogger(FileWatcher.class.getName());

	private String folderPath;
	private String fileName;
	private Set<FileWatcherListener> listeners;
	
	
	public FileWatcher(String folderPath, String fileName) {
		this.folderPath = folderPath;
		this.fileName = fileName;
		this.listeners = new HashSet<>() ;
	}


	@Override
	public void run() {		

		File folder = new File(folderPath);
		if (!folder.exists() ) {
			LOG.error("Cannot watch folder " + folder.getAbsolutePath() + ". It does not exists or is unavailable" );
			return;
		} 
		
		
		LOG.debug("Start watching file " + fileName + " in folder " + folderPath);

		
		WatchService watcher = null;
		try {
			//Questa opzioni dovrebbe essere attivata solo se il config.ini
			//contiene il FLAG che lo abilita
			Path path = Paths.get(folderPath);
			watcher = path.getFileSystem().newWatchService();
			path.register(watcher, StandardWatchEventKinds.ENTRY_MODIFY);
			boolean fileupdated = false;
			
			while (true) {
				WatchKey key = watcher.take();
				for (WatchEvent<?> event : key.pollEvents()) {
					String fileDetectedName = event.context().toString();

					fileupdated = fileDetectedName.equals(fileName);
				}

				if( fileupdated ) {
					LOG.debug("File: " + fileName + " updated!");
					TimeUnit.MILLISECONDS.sleep(1000);
					notifyListeners();
				}

				fileupdated = false;
				boolean valid = key.reset();

				if (!valid) {
					LOG.warn("WatchService is not in a valid status.");
					break;
				} 
			}
		} catch (IOException e) {
			LOG.error("Unexpected IOException while watching file " + fileName, e);
		} catch (InterruptedException e) {
			LOG.error("Unexpected InterruptedException while watching file " + fileName, e);
		} finally {
			if (watcher != null) {
				try {
					watcher.close();
				} catch (IOException e) {
					LOG.error("Error while closing WATCHER", e);
				}
			}
		}
	}
	
	
	public void addFileWatcherListener(FileWatcherListener l) {
		if (!listeners.contains(l)) {
			listeners.add(l);
		}
	}
	
	
	public void removeFileWatcherListener(FileWatcherListener l) {
		if (listeners.contains(l)) {
			listeners.remove(l);
		}
	}
	
	
	private void notifyListeners() {
		for (FileWatcherListener listener : listeners) {
			listener.fileChanged();
		}
	}

}
