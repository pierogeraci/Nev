package it.softstrategy.nevis.rest;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import it.softstrategy.nevis.model.Recording;

/**
 * 
 * @author lgalati
 *
 *
 *
 *	TODO: intercettare le IOException e chiudere le risorse
 */
public class RecListRestService {
	
	private static final Logger LOG = LogManager.getLogger(RecListRestService.class.getName());
	
	private String ip;
	private String port;
	
	public RecListRestService(String ip, String port) {
		this.ip = ip;
		this.port = port;
	}
	
	
	public void addRecordings(List<Recording> recordings) throws IOException {

		String url = "http://" + this.ip +":" + this.port +"/recList/init";


		HttpURLConnection conn = getConnection(new URL(url)) ;

		ObjectMapper mapper = new ObjectMapper();
		ObjectNode messageNode = mapper.createObjectNode();
		ObjectNode recordingsNode = messageNode.putObject("Cams");
		ArrayNode arrayNode = recordingsNode.putArray("Cam");
		
		for(Recording recording : recordings) {
			ObjectNode recordingObj = toJSON(recording, mapper);
			arrayNode.add(recordingObj);
		}



		String jsonString = mapper.writeValueAsString(messageNode);
		
		
		//Send Post request
		DataOutputStream wr = new DataOutputStream(conn.getOutputStream());
		wr.writeBytes(/*message.toString()*/jsonString);
		wr.flush();
		wr.close();
		//LOG.debug(jsonString); Rimosso perché stampa la password in chiaro
		//Get Response from Server
		int responseCode = conn.getResponseCode();

		if (responseCode != HttpURLConnection.HTTP_OK) {
			BufferedReader in = new BufferedReader(
					new InputStreamReader(conn.getInputStream())
					);
			String inputLine;
			StringBuffer response = new StringBuffer();

			while ( (inputLine = in.readLine()) != null) {
				response.append(inputLine);
			}
			in.close();
			LOG.error("REC LIST REST Server ----------\n Response Code %d\n"
					+ "ResponseMessage %s\n---------- ", responseCode, response.toString());
		}
		
	}
	
	public void addRecording(Recording recording) throws IOException {
		String url = "http://" + this.ip +":" + this.port +"/recList/addStream";


		HttpURLConnection conn = getConnection(new URL(url)) ;

		ObjectMapper mapper = new ObjectMapper();
		ObjectNode recordingObj = toJSON(recording, mapper);
		
		String jsonString = mapper.writeValueAsString(recordingObj);

		DataOutputStream wr = new DataOutputStream(conn.getOutputStream());
		wr.writeBytes(/*recordingObj.toString()*/jsonString);
		wr.flush();
		wr.close();

		//Get Response from Server
		int responseCode = conn.getResponseCode();

		if (responseCode != HttpURLConnection.HTTP_OK) {
			BufferedReader in = new BufferedReader(
					new InputStreamReader(conn.getInputStream())
					);
			String inputLine;
			StringBuffer response = new StringBuffer();

			while ( (inputLine = in.readLine()) != null) {
				response.append(inputLine);
			}
			in.close();
			LOG.error("REC LIST REST Server ----------\n Response Code %d\n"
					+ "ResponseMessage %s\n---------- ", responseCode, response.toString());
		}	
	}
	
	public void deleteRecording(Recording recording) throws IOException {

		String url = "http://" + this.ip +":" + this.port +"/recList/deleteStream";


		HttpURLConnection conn = getConnection(new URL(url)) ;

//		JSONObject recordingObj = toJSON(recording);
		ObjectMapper mapper = new ObjectMapper();
		ObjectNode recordingObj = toJSON(recording, mapper);

		String jsonString = mapper.writeValueAsString(recordingObj);
		
		DataOutputStream wr = new DataOutputStream(conn.getOutputStream());
		wr.writeBytes(/*recordingObj.toString()*/jsonString);
		wr.flush();
		wr.close();

		LOG.debug(jsonString);
		//Get Response from Server
		int responseCode = conn.getResponseCode();

		if (responseCode != HttpURLConnection.HTTP_OK)
		{
			BufferedReader in = new BufferedReader(
					new InputStreamReader(conn.getInputStream())
					);
			String inputLine;
			StringBuffer response = new StringBuffer();

			while ( (inputLine = in.readLine()) != null) {
				response.append(inputLine);
			}
			in.close();
			LOG.error("REC LIST REST Server ----------\n Response Code %d\n"
					+ "ResponseMessage %s\n---------- ", responseCode, response.toString());
		}
	}
	
	//TODO: consider better option for the Recording ID
	public void updateRecording(Recording recording) throws IOException{
		String url = "http://" + this.ip +":" + this.port +"/recList/updateStream";


		HttpURLConnection conn = getConnection(new URL(url)) ;

//		JSONObject recordingObj = toJSON(recording);
		ObjectMapper mapper = new ObjectMapper();
		ObjectNode recordingObj = toJSON(recording, mapper);

		DataOutputStream wr = new DataOutputStream(conn.getOutputStream());
		wr.writeBytes(recordingObj.toString());
		wr.flush();
		wr.close();

		//Get Response from Server
		int responseCode = conn.getResponseCode();

		if (responseCode != HttpURLConnection.HTTP_OK)
		{
			BufferedReader in = new BufferedReader(
					new InputStreamReader(conn.getInputStream())
					);
			String inputLine;
			StringBuffer response = new StringBuffer();

			while ( (inputLine = in.readLine()) != null) {
				response.append(inputLine);
			}
			in.close();
			LOG.error("REC LIST REST Server ----------\n Response Code %d\n"
					+ "ResponseMessage %s\n---------- ", responseCode, response.toString());
		}
	}
	
	public List<Recording> getRecordings() throws IOException {
		List<Recording> recordings = new ArrayList<>();
		
		String urlString = "http://" + this.ip +":" + this.port +"/recList/completeList";
		URL url = new URL(urlString);
		HttpURLConnection conn = (HttpURLConnection) url.openConnection();
		conn.setRequestMethod("GET");
//		conn.setRequestProperty("content-type", "application/json");
		conn.setRequestProperty("accept", "application/json");
		
		if (conn.getResponseCode() != HttpURLConnection.HTTP_OK) {
			LOG.error("Rest Error: " + conn.getResponseMessage() );
			return recordings;
		}
		
		BufferedReader br = 
				new BufferedReader(new InputStreamReader((conn.getInputStream())));
		
		String output;
		StringBuffer stringBuffer = new StringBuffer();
		LOG.trace("Output from Server .... \n");
		while ((output = br.readLine()) != null) {
//			System.out.println(output);
			stringBuffer.append(output);
		}

		conn.disconnect();
		
		ObjectMapper mapper = new ObjectMapper();
		
		JsonNode root = mapper.readTree(stringBuffer.toString());
//		LOG.debug(root);
		
		JsonNode camsNode = root.path("Cams");
		JsonNode camNode = camsNode.path("Cam");
		if (camNode.isArray()) {
			for (JsonNode node : camNode) {
				Recording recording = toRecording(node);
				recordings.add(recording);
			}
		}
		
		return recordings;
	}
	
	
	//-------------------------------------------------
	//
	//				UTILITY METHODS
	//
	//-------------------------------------------------
	
	private ObjectNode toJSON(Recording recording, ObjectMapper mapper) {
		
		ObjectNode objectNode = mapper.createObjectNode();
		
		if (recording != null) {
			//N.B. il carattere "@" serve al Serializzatore
			objectNode.put("@id", recording.getSlotId());
			
			objectNode.put("DepthRec", recording.getDepthRec());
			objectNode.put("Description", recording.getDescription());
			objectNode.put("Encoder", recording.getEncoder());
			objectNode.put("Ip", recording.getIp());
			objectNode.put("IsOnvif", recording.getIsOnvif());
			objectNode.put("Mac", recording.getMac());
			objectNode.put("Model", recording.getModel());
			objectNode.put("Password", recording.getPassword());
			objectNode.put("Pid", recording.getPid());
			objectNode.put("Quality", recording.getQuality());
			objectNode.put("SensorId", recording.getSensorId());
			objectNode.put("SlotFolder", recording.getSlotFolder());
			objectNode.put("Status", recording.getStatus());
			objectNode.put("Url", recording.getUrl());
			objectNode.put("UrlLive", recording.getUrlLive());
			objectNode.put("Username", recording.getUsername());
			objectNode.put("Vendor", recording.getVendor());
			objectNode.put("VideoSourceId", recording.getVideoSourceId());
			
		}
		
		return objectNode;
	}
	
	private Recording toRecording(JsonNode node) {
		Recording recording = null;
		
		if (node != null) {
			recording = new Recording();
			recording.setSlotId(node.path("@id").asText());
			
			recording.setDepthRec(node.path("DepthRec").asInt());
			recording.setDescription(node.path("Description").asText());
			recording.setEncoder(node.path("Encoder").asText());
			recording.setIp(node.path("Ip").asText());
			recording.setIsOnvif(node.path("IsOnvif").asBoolean());
			recording.setMac(node.path("Mac").asText());
			recording.setModel(node.path("Model").asText());
			recording.setPassword(node.path("Password").asText());
			recording.setPid(node.path("Pid").asInt());
			recording.setQuality(node.path("Quality").asText());
			recording.setSensorId(node.path("SensorId").asInt());
			recording.setSlotFolder(node.path("SlotFolder").asText());
			recording.setUrl(node.path("Url").asText());
			recording.setUrlLive(node.path("UrlLive").asText());
			recording.setUsername(node.path("Username").asText());
			recording.setVendor(node.path("Vendor").asText());
			recording.setVideoSourceId(node.path("VideoSourceId").asText());
			
		}
		
		return recording;
	}
	
	private HttpURLConnection getConnection(URL url) throws IOException {	
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			
			//add request header
			conn.setRequestMethod("POST");
			conn.setRequestProperty("content-type", "application/json");
			conn.setRequestProperty("accept", "application/json");
			conn.setDoOutput(true);
			conn.setDoInput(true);
			
			return conn;
	}

}
