
package it.softstrategy.nevis;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.google.common.eventbus.EventBus;


/**
 * @author lgalati
 *
 */
public class AppHelper {

	private static final Logger LOG = LogManager.getLogger(AppHelper.class.getName());
	
	
	
	private EventBus eventBus;
	
	
	
	private AppHelper() {
		eventBus = new EventBus();
	}
	
	//SINGLETON
	private static class Helper {
		private final static AppHelper INSTANCE = new AppHelper();
	}
	
	public static AppHelper getInstance() {
		return Helper.INSTANCE;
	}

	//PUBLIC
	public EventBus getEventBus() {
		return eventBus;
	}

}
