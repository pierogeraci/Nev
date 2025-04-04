
package it.softstrategy.nevis.events;

import java.util.List;

import it.softstrategy.nevis.util.NevisVideoSource;

/**
 * @author lgalati
 *
 */
public class VideoSourceEvent {
	
	
	private List<NevisVideoSource> videoSources;

	
	public VideoSourceEvent(List<NevisVideoSource> videoSources) {
		this.videoSources = videoSources;
	}


	public List<NevisVideoSource> getVideoSources() {
		return videoSources;
	}
	
	
}
