package it.softstrategy.nevis.util;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map.Entry;
import java.util.SortedMap;
import java.util.TreeMap;

import com.fasterxml.jackson.annotation.JsonInclude.Include;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import com.fasterxml.jackson.databind.node.ObjectNode;

public class LoadBalanceUtil {
	
	public static final String VIDEOSOURCES_KEY = "videosources";
	public static final String VIDEOSOURCE_KEY = "videosource";
	public static final String PROFILE_KEY = "profile";
	
	public static String convertMapToString(SortedMap<NevisVideoSource, String> balancedMap) throws JsonProcessingException {
		JsonNodeFactory factory = new JsonNodeFactory(false);
		ObjectMapper mapper = new ObjectMapper();
		mapper.setSerializationInclusion(Include.NON_NULL);
		
		ObjectNode root = factory.objectNode();
		ArrayNode list = root.putArray(VIDEOSOURCES_KEY);
		for( Entry<NevisVideoSource, String> entry : balancedMap.entrySet() ) {
			NevisVideoSource videoSource = entry.getKey();
			String profileId = entry.getValue();
			
			ObjectNode objNode = list.addObject();
			objNode.putPOJO(VIDEOSOURCE_KEY, videoSource);
			objNode.put(PROFILE_KEY, profileId);
		}
		
		return mapper.writeValueAsString(root);
	}
	
	public static SortedMap<NevisVideoSource, String> readMapFromString(String stringList) throws JsonProcessingException, IOException {

		SortedMap<NevisVideoSource, String> result = new TreeMap<>(new NevisVideoSourceComparator());
		ObjectMapper mapper = new ObjectMapper();
		mapper.setSerializationInclusion(Include.NON_NULL);
		
		JsonNode root = mapper.readTree(stringList);
		
		ArrayNode jsonArray = (ArrayNode) root.get(VIDEOSOURCES_KEY);
		for (int index = 0; index < jsonArray.size(); index++) {
			JsonNode objNode = jsonArray.get(index);
			NevisVideoSource videoSource = mapper.treeToValue(objNode.get(VIDEOSOURCE_KEY), NevisVideoSource.class);
			String profileId = mapper.treeToValue(objNode.get(PROFILE_KEY), String.class);
			result.put(videoSource, profileId);
		}
		
		return result;
	}
	
	public static String convertListToString(/*List<NevisCamera> cameras*/List<NevisVideoSource> videoSources) throws JsonProcessingException {
		JsonNodeFactory factory = new JsonNodeFactory(false);
		ObjectMapper mapper = new ObjectMapper();
		mapper.setSerializationInclusion(Include.NON_NULL);
		
		ObjectNode root = factory.objectNode();
		ArrayNode list = root.putArray(VIDEOSOURCES_KEY);
		
		for (NevisVideoSource videoSource: videoSources) {
			list.addPOJO(videoSource);
		}
		
		return mapper.writeValueAsString(root);
	}
	
	public static List<NevisVideoSource> readListFromString(String stringList) throws JsonProcessingException, IOException {
		List<NevisVideoSource> result = new ArrayList<>();
		ObjectMapper mapper = new ObjectMapper();
		mapper.setSerializationInclusion(Include.NON_NULL);
		
		JsonNode root = mapper.readTree(stringList);
		
		ArrayNode jsonArray = (ArrayNode) root.get(VIDEOSOURCES_KEY);
		for( int index = 0; index < jsonArray.size(); index++) {
			JsonNode objNode = jsonArray.get(index);
			NevisVideoSource camera = mapper.treeToValue(objNode, NevisVideoSource.class);
			result.add(camera);
		}
		
		return result;
	}

}
