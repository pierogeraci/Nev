package it.softstrategy.nevis.log;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.io.Serializable;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Date;

import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.core.Filter;
import org.apache.logging.log4j.core.Layout;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.appender.AbstractAppender;
import org.apache.logging.log4j.core.config.plugins.Plugin;
import org.apache.logging.log4j.core.config.plugins.PluginAttribute;
import org.apache.logging.log4j.core.config.plugins.PluginElement;
import org.apache.logging.log4j.core.config.plugins.PluginFactory;
import org.apache.logging.log4j.core.layout.PatternLayout;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

@Plugin(name="RESTAppender", category="Core", elementType="Appender", printObject=true)
public class RESTAppender extends AbstractAppender {
	
	private String ip;
	private String port;
	private String path;
	private String sender;

	protected RESTAppender(String name, Filter filter, Layout<? extends Serializable> layout,
			boolean ignoreExceptions) {
		super(name, filter, layout, ignoreExceptions);
		ip = null;
		port = null;
		path = null;
		sender = null;
		
	}

	@Override
	public void append(LogEvent event) {
		String url = "http://" + this.ip +":" + this.port +"/" + path;
		
		try {
			URL obj = new URL(url);
			HttpURLConnection conn ;
			
			//add request header
			conn = (HttpURLConnection) obj.openConnection();
			conn.setRequestMethod("POST");
			conn.setRequestProperty("content-type", "application/json");
			conn.setRequestProperty("accept", "application/json");
			conn.setDoOutput(true);
			conn.setDoInput(true);
				
			ObjectMapper mapper = new ObjectMapper();
			ObjectNode logObject;
			if (event.getLevel() == Level.FATAL) {
				logObject = produceFatalJson (mapper, event);
			} else {
				logObject = produceGenericJson(mapper, event);
			}
			

			
			String jsonString = mapper.writeValueAsString(logObject);
			LOGGER.debug(jsonString);
			//Send Post request
			DataOutputStream wr = new DataOutputStream(conn.getOutputStream());
			wr.writeBytes(jsonString);
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
				LOGGER.error("REST Manager Server ----------\n Response Code %d\n"
						+ "ResponseMessage %s\n---------- ", responseCode, response.toString());
			}
			
			
			
		} catch (Exception e) {
			LOGGER.error("RESTAppender can't send ", e);
		} finally {
			
		}

	}
	
	@PluginFactory
	public static RESTAppender createAppender(
			@PluginAttribute("name") String name,
			@PluginElement("Layout") Layout<? extends Serializable> layout,
			@PluginElement("Filter") final Filter filter,
			@PluginAttribute("ignoreExceptions") boolean ignoreExceptions,
			@PluginAttribute("sender") String sender,
			@PluginAttribute("ip") String ip,
			@PluginAttribute("port") String port,
			@PluginAttribute("path") String path ) {
		
		if (name == null) {
			LOGGER.error("No name provided for RESTAppender");
			return null;
		}
		
		if (sender == null) {
			LOGGER.error("No sender name provided for RESTAppender");
			return null;
		}
		
		if (ip == null) {
			LOGGER.error("No IP provided for RESTAppender");
			return null;
		}
		
		if (port == null) {
			LOGGER.error("No PORT provided for RESTAppender");
			return null;
		}
		
		if (path == null) {
			path = "";
		}
		
		if (layout == null) {
			layout = PatternLayout.createDefaultLayout();
		}
		
		RESTAppender restAppender = new RESTAppender(name, filter, layout, ignoreExceptions);
		restAppender.ip = ip;
		restAppender.port = port;
		restAppender.path = path;
		restAppender.sender = sender;
		
		return restAppender;
		
	}
	
	
	//Private Utility Methods
	private ObjectNode produceFatalJson (ObjectMapper mapper, LogEvent event) {
		
		ObjectNode jsonLog = mapper.createObjectNode();
		jsonLog.put("process", "NEVIS_FATAL");
		jsonLog.put("msg_type", event.getLevel().toString());
		

		ObjectNode logContent = jsonLog.putObject("log");
		logContent.put("TIMESTAMP", event.getTimeMillis());
		logContent.put("COMPONENT", sender);
		String loggerName = event.getLoggerName();
		loggerName = loggerName.substring(loggerName.lastIndexOf(".") >= 0 ? loggerName.lastIndexOf(".") + 1 : 0); 
		
		String message = event.getMessage().getFormattedMessage();
		String[] tokens = message.split("-");
		String code = tokens[0].trim();
		int status = Integer.parseInt( tokens[1].trim() );
		String msg = tokens[2];
		
		
		//JSONObject.escape(event.getMessage().getFormattedMessage());
		if (event.getThrown() != null) {
			msg += " - " + event.getThrown().getMessage();
		}
		logContent.put("CODE", code);
		logContent.put("STATUS", status);
		logContent.put("MSG", msg);
		
		return jsonLog;
	}
	
	private ObjectNode produceGenericJson (ObjectMapper mapper, LogEvent event) {
		
		ObjectNode jsonLog = mapper.createObjectNode();
		jsonLog.put("process", sender);
		jsonLog.put("msg_type", event.getLevel().toString());
		

		ObjectNode logContent = jsonLog.putObject("log");
		logContent.put("TIMESTAMP", (new Date()).getTime() );
		String loggerName = event.getLoggerName();
		loggerName = loggerName.substring(loggerName.lastIndexOf(".") >= 0 ? loggerName.lastIndexOf(".") + 1 : 0); 
		//String msg = loggerName + " - " + event.getMessage().getFormattedMessage();//JSONObject.escape(event.getMessage().getFormattedMessage());
		String msg = event.getMessage().getFormattedMessage();
		if (event.getLevel() == Level.ERROR && event.getThrown() != null) {
			msg += " - " + event.getThrown().getMessage();
		}
				
		logContent.put("MSG", msg);
		
		return jsonLog;
	}

}
