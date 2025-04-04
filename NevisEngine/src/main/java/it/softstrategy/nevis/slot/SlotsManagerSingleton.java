package it.softstrategy.nevis.slot;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map.Entry;
import java.util.SortedMap;
import java.util.TreeMap;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.softstrategy.nevis.model.RecordingConfigurationEntry;
import it.softstrategy.nevis.model.Slot;
import it.softstrategy.nevis.util.ConversionUtil;
import it.softstrategy.nevis.util.RecordingConfigurationEntryComparator;
import it.softstrategy.nevis.util.SlotComparator;

/**
 * @author lgalati
 *
 *
 *	It's been used the Bill Pugh's version of Singleton Design Pattern 
 *	N.B. Thread Safe implementation
 */
public class SlotsManagerSingleton {
	
	private static final Logger LOG = LogManager.getLogger(SlotsManagerSingleton.class.getName());
	
	
//	private final NevisConfiguration configuration;
	
	//Numero massimo di Slot attivabili. Viene impostato in fase di
	//controllo dell'attivazione della licenza
	private int maxActiveSlots = 0;
	
	// Archivio contente la lista delle associazioni Slot Id - Ottiche 
	// usate dal sistema NeVis
//	private SlotsArchive archive;
	
	

	/**
	 * Costruttore privato, in quanto la creazione dell'istanza deve essere controllata.
	 */
	private SlotsManagerSingleton() {		
	
//		configuration = new NevisConfigurationImpl();
		
		
	}
	
	
	
	
	public  void setMaxActiveSlots(int maxActiveSlots) {
		this.maxActiveSlots = maxActiveSlots;
		System.out.println("MaxActiveSlot = " + maxActiveSlots);
		
		LOG.info("Manager Set Up - Max number of recordings = " + maxActiveSlots);
		
//		loadArchiveFromDisk();
//		
//		setUpArchive();
		
	}
	
	
	
	
	/**
	 * La classe Helper viene caricata/inizializzata alla prima esecuzione di getInstance()
	 * ovvero al primo accesso a Helper.INSTANCE, ed in modo thread-safe.
	 * Anche l'inizializzazione dell'attributo statico, pertanto, viene serializzata.
	 */
	private static class Helper {
		private final static SlotsManagerSingleton INSTANCE = new SlotsManagerSingleton();
	}
	
	/**
	 * Punto di accesso al Singleton. Ne assicura la creazione thread-safe
	 * solo all'atto della prima chiamata.
	 * @return il Singleton corrispondente
	 */
	public static SlotsManagerSingleton getInstance() {
		return Helper.INSTANCE;
	}

	
	//Metodo per il nuovo componente RecordingProcessManager
	public synchronized SortedMap<RecordingConfigurationEntry, Integer>  associateSlots(List<RecordingConfigurationEntry> configurationEntries) throws IOException {
		SortedMap<RecordingConfigurationEntry, Integer> ret = new TreeMap<>(new RecordingConfigurationEntryComparator());
		
		
		List<Slot> slots = loadSlotsFromFileSystem();
		
		Collections.sort(configurationEntries, new RecordingConfigurationEntryComparator());
		int associated = 0;
		for (RecordingConfigurationEntry configEntry : configurationEntries) {

			if (associated < maxActiveSlots) {
				//Search for an already associated slot
				Slot alreadyAssociatedSlot = null;
				for (Slot slot : slots) {
					if (slot.getVideoSourceId() != null && slot.getQuality() != null) {
						if (configEntry.getVideoSourceId().equals(slot.getVideoSourceId())
								&& configEntry.getQuality().equals(slot.getQuality())) {
							alreadyAssociatedSlot = slot;
							break;
						}
					}

				}

				if (alreadyAssociatedSlot != null) {
					LOG.info("Found slot " + alreadyAssociatedSlot.getId() + " already associated to video source " + configEntry.getVideoSourceId() );
					ret.put(configEntry, alreadyAssociatedSlot.getId());
					associated++;
					continue;
				} else {
					
					//Search for a free slot
					Slot slot = null;
					for (Slot currSlot: slots) {
						if (currSlot.getVideoSourceId() == null && currSlot.getQuality() == null) {//Questo controllo ha senso in quanto la lista degli slot è ordinata per id
							slot = currSlot;
							break;
						}
					}

					if (slot == null) {
						slot = new Slot();
						slot.setId(slots.size() + 1);
						slots.add(slot);
					}
					
					LOG.info("Associating slot " + slot.getId() + " to Video Source [" + configEntry.getVideoSourceId() + "]");
					slot.setVideoSourceId(configEntry.getVideoSourceId());
					slot.setQuality(configEntry.getQuality());
					//slot.setType("M");
					ret.put(configEntry, slot.getId());
					associated++;
					continue;
				}
				
			} else {
				LOG.warn("No slot available for Video Source " + configEntry.getVideoSourceId());
			}
		}
		
		
		LOG.debug("Association: ");
		for (Entry<RecordingConfigurationEntry, Integer> a : ret.entrySet()) {
			LOG.debug("VideoSourceId=" + a.getKey().getVideoSourceId() + " - slotId=" + a.getValue());
		}
		
		
		return ret;
	}
	
	
	
	
	//METODI PRIVATI	
	private List<Slot> loadSlotsFromFileSystem() {
		
		List<Slot> slots = new ArrayList<>();

		DirectoryStream.Filter<Path> filter = new DirectoryStream.Filter<Path>() {
			public boolean accept(Path file) throws IOException {
//				LOG.debug("Filtrando " + file.getFileName());
				if (file.getFileName().toString().equals("public") 
						|| file.getFileName().toString().equals("lost+found")) {
//					LOG.debug("Filtrato");
					return false;
					
					
				}
//				LOG.debug("Accettato");
				return true;
			}
		};

		try (DirectoryStream<Path> directoryStream = Files.newDirectoryStream(Paths.get("/nevis"), filter)) {
			for (Path path : directoryStream) {
//				fileNames.add(path.toString());
//				LOG.debug("Found folder " + path.getFileName());
				Slot slot = ConversionUtil.createSlot(path.getFileName().toString());
				if (slot != null) {
//					LOG.debug("Adding slot " + slot);
					slots.add(slot);
				}
				
			}
		} catch (IOException ex) {
			LOG.error("Error", ex);
		}
		
		
		//Fill the list with missing slots
		Slot max = slots.isEmpty() ? null : Collections.max(slots, new SlotComparator());
		
		if (max != null) {
			List<Slot> missingSlots = new ArrayList<>();
			for (int slotIndex = 1; slotIndex < max.getId() ; slotIndex ++) {
				Slot foundSlot = null;
				for (Slot slot : slots) {
					if (slot.getId() == slotIndex) {
						foundSlot = slot;
						break;
					}
				}

				if (foundSlot == null) {
					Slot missingSlot = new Slot();
					missingSlot.setId(slotIndex);
					missingSlots.add(missingSlot);
				}
			}

			slots.addAll(missingSlots);

			//Ordering the list
			Collections.sort(slots, new SlotComparator());
		}
		
		if (slots.isEmpty()) {
			LOG.debug("Slots with recording data in the system :");
		} else {
			LOG.debug("Slots with recording data in the system :");
			for (Slot s : slots) {
				LOG.debug("Slots:" + s);
			}
		}
		
		return slots;
	}
	
}
