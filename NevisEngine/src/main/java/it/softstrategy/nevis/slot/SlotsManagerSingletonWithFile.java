/**
 * 
 */
package it.softstrategy.nevis.slot;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.function.Predicate;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.simpleframework.xml.Serializer;
import org.simpleframework.xml.core.Persister;

import it.softstrategy.nevis.configuration.NevisConfiguration;
import it.softstrategy.nevis.configuration.NevisConfigurationImpl;
import it.softstrategy.nevis.model.RecordingConfigurationEntry;
import it.softstrategy.nevis.model.SlotsArchive;
import it.softstrategy.nevis.model.SlotsArchiveEntry;
import it.softstrategy.nevis.util.RecordingConfigurationEntryComparator;

/**
 * @author lgalati
 *
 *  It's been used the Bill Pugh's version of Singleton Design Pattern 
 *	N.B. Thread Safe implementation
 */
public class SlotsManagerSingletonWithFile {
	
	private static final Logger LOG = LogManager.getLogger(SlotsManagerSingletonWithFile.class.getName());
	
	
	
	
	private final NevisConfiguration configuration;
	
	//Numero massimo di Slot attivabili. Viene impostato in fase di
	//controllo dell'attivazione della licenza
	private int maxActiveSlots = 0;
	
	// Archivio contente la lista delle associazioni Slot Id - Ottiche 
	// usate dal sistema NeVis
	private SlotsArchive archive;
	
	

	/**
	 * Costruttore privato, in quanto la creazione dell'istanza deve essere controllata.
	 */
	private SlotsManagerSingletonWithFile() {		
	
		configuration = new NevisConfigurationImpl();
		
		
	}
	
	
	
	
	public  void setMaxActiveSlots(int maxActiveSlots) {
		this.maxActiveSlots = maxActiveSlots;
		System.out.println("MaxActiveSlot = " + maxActiveSlots);
		
		LOG.info("Manager Set Up - Max number of recordings = " + maxActiveSlots);
		
		loadArchiveFromDisk();
		
		setUpArchive();
		
	}
	
	
	
	
	/**
	 * La classe Helper viene caricata/inizializzata alla prima esecuzione di getInstance()
	 * ovvero al primo accesso a Helper.INSTANCE, ed in modo thread-safe.
	 * Anche l'inizializzazione dell'attributo statico, pertanto, viene serializzata.
	 */
	private static class Helper {
		private final static SlotsManagerSingletonWithFile INSTANCE = new SlotsManagerSingletonWithFile();
	}
	
	/**
	 * Punto di accesso al Singleton. Ne assicura la creazione thread-safe
	 * solo all'atto della prima chiamata.
	 * @return il Singleton corrispondente
	 */
	public static SlotsManagerSingletonWithFile getInstance() {
		return Helper.INSTANCE;
	}
	
	
	
	
	public synchronized boolean deassociateSlot(String videoSourceId) {
		SlotsArchiveEntry entry = findAssociatedSlotArchiveEntry(videoSourceId);
		
		if (entry != null) {
			entry.setUsed(false);
			return true;
		} 
		
		return false;
	}

	
	//Metodo per il nuovo componente RecordingProcessManager
	public synchronized SortedMap<RecordingConfigurationEntry, Integer>  associateSlots(List<RecordingConfigurationEntry> configurationEntries) throws IOException {
		SortedMap<RecordingConfigurationEntry, Integer> ret = new TreeMap<>(new RecordingConfigurationEntryComparator());	
		
		boolean update = false;
		//We need to break this task in two phases
		
		//PHASE 1 - Search for Slot associeted to Video Source in the past
		List<RecordingConfigurationEntry> noSlotInThePast = new ArrayList<>();
		for (RecordingConfigurationEntry configEntry : configurationEntries) {

			if (usedSlotsCount() < maxActiveSlots) {
				//Search for a slot associated to this videoSourceId in the past
				SlotsArchiveEntry archiveEntry = findAssociatedSlotArchiveEntry(configEntry.getVideoSourceId());

				if (archiveEntry != null && !archiveEntry.isUsed()) {
					LOG.info("Found slot " + archiveEntry.getSlotId() + " already associated to video source [  " + configEntry.getVideoSourceId() + "]");
					
					archiveEntry.setIpAddress(configEntry.getIpAddress());
					archiveEntry.setMacAddress(configEntry.getMacAddress());
					archiveEntry.setVideoSourceId(configEntry.getVideoSourceId());
					archiveEntry.setTimestamp(new Date());
					archiveEntry.setUsed(true);
					
					update = true;
					
					ret.put(configEntry, archiveEntry.getSlotId());
				} else {
					noSlotInThePast.add(configEntry);
				}
			}
		}
		
		//PHASE 1 - Search for a new Slot or a previously used one for  Video Source
		for (RecordingConfigurationEntry configEntry : noSlotInThePast) {

			if (usedSlotsCount() < maxActiveSlots) {
				
				SlotsArchiveEntry archiveEntry = findSlotArchiveEntry(configEntry.getVideoSourceId());
				
				//Updating the archive
				//SlotId value was already setup in the setUpArchive() method
				//archiveEntry.setSlotId(archive.getArchive().size() + 1);
				archiveEntry.setIpAddress(configEntry.getIpAddress());
				archiveEntry.setMacAddress(configEntry.getMacAddress());
				archiveEntry.setVideoSourceId(configEntry.getVideoSourceId());
				archiveEntry.setTimestamp(new Date());
				archiveEntry.setUsed(true);
//				archive.getArchive().add(newEntry); The slot was already added to the archive in the setUpArchive() method
				
				update = true;
				
				ret.put(configEntry, archiveEntry.getSlotId());

			} else {
				LOG.warn("No slot available for Video Source " + configEntry.getVideoSourceId());
			}
		}
		

		if (update) {
			writeArchiveToDisk();
		}
		
		return ret;
	}
	
	
	
	
	//METODI PRIVATI
	
	private void loadArchiveFromDisk() {
		String pathname = configuration.getWorkHistoryFolder() + File.separator + "slots_archive.xml";//NevisMain.SERVICE_FOLDER_HISTORY + File.separator + "slots_archive.xml";
		//Caricamento storico
		Serializer serializer = new Persister();
		try {
			archive = serializer.read(SlotsArchive.class, new File(pathname));
		} catch (Exception e) {
			LOG.error("Could not load Slot Archive from disk. Error while opening file " + pathname, e);
			archive = new SlotsArchive();
			archive.setArchive(new ArrayList<>());
		} 
	}
	
	private void writeArchiveToDisk() {
		//Salvataggio dello storico su disco
		Serializer serializer = new Persister();
		
		String pathname = /*NevisMain.SERVICE_FOLDER_HISTORY*/configuration.getWorkHistoryFolder() + File.separator + "slots_archive.xml";
		try {
			serializer.write(archive, new File(pathname));
		} catch (Exception e) {
			LOG.error("Can't write Slots Archive info to file " + pathname, e);
		}
	}
	
	private int usedSlotsCount() {
		int count = 0;
		
		for (SlotsArchiveEntry entry : archive.getArchive()) {
			if (entry.isUsed()) {
				count++;
			}
		}
		
		return count;
	}
	
	private SlotsArchiveEntry findAssociatedSlotArchiveEntry(String videoSourceId) {
		SlotsArchiveEntry ret = null;

		for (SlotsArchiveEntry entry : archive.getArchive()) {

			if (entry.getVideoSourceId() != null && entry.getVideoSourceId().equals(videoSourceId) 
					//&& entry.getIpAddress().equals(videoSource.getNevisCamera().getIpAddress()) 
					) {
				ret = entry;
				break;
			}
		}
		
		return ret;
	}
	
	private SlotsArchiveEntry findSlotArchiveEntry(String videoSourceId) {
		SlotsArchiveEntry ret = null;
		
//		//Search for a slot associated to this videoSourceId in the past
//		ret = findAssociatedSlotArchiveEntry(videoSourceId);
//		
//		if (ret != null && !ret.isUsed()) {
//			LOG.info("Found slot " + ret.getSlotId() + " already associated to videosource [ to Video Source " + videoSourceId + "]");
//			return ret;
//		}
		
		//If the Recording didn't have any slot in the past search for a new slot
		for (SlotsArchiveEntry entry : archive.getArchive()) {

			if (entry.getVideoSourceId() == null) {
				ret = entry;
				break;
			}

		}
		
		if (ret != null && !ret.isUsed()) {
			LOG.info("Associating new slot " + ret.getSlotId() + " to Video Source [" + videoSourceId + "]");
			return ret;
		}
		
		
		//If there is not a new slot, find a not used one
		for (SlotsArchiveEntry entry : archive.getArchive()) {
			if (!entry.isUsed()) {
				ret = entry;
				LOG.info("Associating slot " + ret.getSlotId() + " to Video Source [" + videoSourceId + "]");
				break;
			}
		}
		
		
		return ret;
	}
	
	
	//Use this method to setup the Archive data structure
	//after reading its content from the disk
	private void setUpArchive() {
		
		LOG.info("Slot Archive from disk contains " + archive.getArchive().size() + " slot <--> recording associations");
		
		//Ordering the archive by slotId
		Collections.sort(archive.getArchive(), new Comparator<SlotsArchiveEntry>() {

			@Override
			public int compare(SlotsArchiveEntry e1, SlotsArchiveEntry e2) {
				
				return e1.getSlotId().compareTo(e2.getSlotId());
				
			}
		});
		
		
		//Setting all the "used" flag to false
		archive.getArchive().forEach(entry ->  entry.setUsed(false));
//		System.out.println(archive.getArchive());

		//Align the dimension of the archive to the maxActiveSlots
		if (archive.getArchive().size() < maxActiveSlots) {
			Integer index = archive.getArchive().size();
			while (index < maxActiveSlots) {
				SlotsArchiveEntry newEntry = new SlotsArchiveEntry();
				newEntry.setSlotId(++index);
				newEntry.setUsed(false);
				archive.getArchive().add(newEntry);
			}
		} else if ( archive.getArchive().size() > maxActiveSlots) {
			archive.getArchive().removeIf(isNotActive());
		}
		
	}
	
	
	//Filtro sul maxActiveSlot
	private Predicate<SlotsArchiveEntry> isNotActive() {
		return s -> s.getSlotId() > maxActiveSlots;
	}

}
