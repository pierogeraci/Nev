package it.softstrategy.nevis.onvif.soap;

import java.net.ConnectException;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.bind.UnmarshalException;
import javax.xml.bind.Unmarshaller;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.soap.MessageFactory;
import javax.xml.soap.SOAPConnection;
import javax.xml.soap.SOAPConnectionFactory;
import javax.xml.soap.SOAPConstants;
import javax.xml.soap.SOAPElement;
import javax.xml.soap.SOAPEnvelope;
import javax.xml.soap.SOAPException;
import javax.xml.soap.SOAPHeader;
import javax.xml.soap.SOAPMessage;
import javax.xml.soap.SOAPPart;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.w3c.dom.Document;

public class SOAP {

//	private static final Logger LOG = LogManager.getLogger(SOAP.class.getName());
//
//	private OnvifDevice onvifDevice;
//
//	public SOAP(OnvifDevice onvifDevice) {
//		super();
//
//		this.onvifDevice = onvifDevice;
//	}
//
//	public Object createSOAPDeviceRequest(Object soapRequestElem, Object soapResponseElem, boolean needsAuthentification) throws SOAPException,
//			ConnectException {
//		return createSOAPRequest(soapRequestElem, soapResponseElem, onvifDevice.getDeviceUri(), needsAuthentification);
//	}
//
//	public Object createSOAPPtzRequest(Object soapRequestElem, Object soapResponseElem, boolean needsAuthentification) throws SOAPException, ConnectException {
//		return createSOAPRequest(soapRequestElem, soapResponseElem, onvifDevice.getPtzUri(), needsAuthentification);
//	}
//
//	public Object createSOAPMediaRequest(Object soapRequestElem, Object soapResponseElem, boolean needsAuthentification) throws SOAPException, ConnectException {
//		return createSOAPRequest(soapRequestElem, soapResponseElem, onvifDevice.getMediaUri(), needsAuthentification);
//	}
//
//	public Object createSOAPImagingRequest(Object soapRequestElem, Object soapResponseElem, boolean needsAuthentification) throws SOAPException,
//			ConnectException {
//		return createSOAPRequest(soapRequestElem, soapResponseElem, onvifDevice.getImagingUri(), needsAuthentification);
//	}
//
//	public Object createSOAPEventsRequest(Object soapRequestElem, Object soapResponseElem, boolean needsAuthentification) throws SOAPException,
//			ConnectException {
//		return createSOAPRequest(soapRequestElem, soapResponseElem, onvifDevice.getEventsUri(), needsAuthentification);
//	}
//
//	/**
//	 * 
//	 * @param soapResponseElem
//	 *            Answer object for SOAP request
//	 * @return SOAP Response Element
//	 * @throws SOAPException
//	 * @throws ConnectException
//	 */
//	public Object createSOAPRequest(Object soapRequestElem, Object soapResponseElem, String soapUri, boolean needsAuthentification) throws ConnectException,
//			SOAPException {
//		SOAPConnection soapConnection = null;
//		SOAPMessage soapResponse = null;
//		
//		if (soapResponseElem == null) {
//			throw new NullPointerException("Improper SOAP Response Element given (is null).");
//		}
//
//		try {
//			// Create SOAP Connection
//			SOAPConnectionFactory soapConnectionFactory = SOAPConnectionFactory.newInstance();
//			soapConnection = soapConnectionFactory.createConnection();
//
//			SOAPMessage soapMessage = createSoapMessage(soapRequestElem, needsAuthentification);
//
//			// Print the request message
////			if (isLogging()) {
////				System.out.print("Request SOAP Message (" + soapRequestElem.getClass().getSimpleName() + "): ");
////				soapMessage.writeTo(System.out);
////				System.out.println();
////			}
////			LOG.debug("Request SOAP Message (" + soapRequestElem.getClass().getSimpleName() + "): " + soapMessage.toString());
//
//			soapResponse = soapConnection.call(soapMessage, soapUri);
//
//			// print SOAP Response
////			if (isLogging()) {
////				System.out.print("Response SOAP Message (" + soapResponseElem.getClass().getSimpleName() + "): ");
////				soapResponse.writeTo(System.out);
////				System.out.println();
////			}
////			LOG.debug("Response SOAP Message (" + soapResponseElem.getClass().getSimpleName() + "): " + soapMessage.toString());
////			soapResponse.writeTo(System.out);
//
//			
//
//			Unmarshaller unmarshaller = JAXBContext.newInstance(soapResponseElem.getClass()).createUnmarshaller();
//			try {
//				try {
//					soapResponseElem = unmarshaller.unmarshal(soapResponse.getSOAPBody().extractContentAsDocument());
//				}
//				catch (SOAPException e) {
//					// Second try for SOAP 1.2
//					// Sorry, I don't know why it works, it just does o.o
//					soapResponseElem = unmarshaller.unmarshal(soapResponse.getSOAPBody().extractContentAsDocument());
//				}
//			}
//			catch (UnmarshalException e) {
//				// Fault soapFault = (Fault)
//				// unmarshaller.unmarshal(soapResponse.getSOAPBody().extractContentAsDocument());
//				LOG.warn("Could not unmarshal, ended in SOAP fault.");
//				// throw new SOAPFaultException(soapFault);
//			}
//
//			return soapResponseElem;
//		}
////		catch (SocketException e) {
////			throw new ConnectException(e.getMessage());
////		}
//		catch (SOAPException e) {
//			LOG.error(
//					"Unexpected response. Response should be from class " + soapResponseElem.getClass() + ", but response is: " + soapResponse);
//			throw e;
//		}
//		catch (ParserConfigurationException | JAXBException /*| IOException*/ e) {
//			LOG.error("Unhandled exception: " + e.getMessage(), e);
////			e.printStackTrace();
//			return null;
//		}
//		finally {
//			try {
//				soapConnection.close();
//			}
//			catch (SOAPException e) {
//			}
//		}
//	}
//
//	protected SOAPMessage createSoapMessage(Object soapRequestElem, boolean needAuthentification) throws SOAPException, ParserConfigurationException,
//			JAXBException {
//		MessageFactory messageFactory = MessageFactory.newInstance(SOAPConstants.SOAP_1_2_PROTOCOL);
//		SOAPMessage soapMessage = messageFactory.createMessage();
//
//		Document document = DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument();
//		Marshaller marshaller = JAXBContext.newInstance(soapRequestElem.getClass()).createMarshaller();
//		marshaller.marshal(soapRequestElem, document);
//		soapMessage.getSOAPBody().addDocument(document);
//
//		// if (needAuthentification)
//		createSoapHeader(soapMessage);
//
//		soapMessage.saveChanges();
//		return soapMessage;
//	}
//
//	protected void createSoapHeader(SOAPMessage soapMessage) throws SOAPException {
//		onvifDevice.createNonce();
//		String encrypedPassword = onvifDevice.getEncryptedPassword();
//		if (encrypedPassword != null && onvifDevice.getUsername() != null) {
//
//			SOAPPart sp = soapMessage.getSOAPPart();
//			SOAPEnvelope se = sp.getEnvelope();
//			SOAPHeader header = soapMessage.getSOAPHeader();
//			se.addNamespaceDeclaration("wsse", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd");
//			se.addNamespaceDeclaration("wsu", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd");
//
//			SOAPElement securityElem = header.addChildElement("Security", "wsse");
//			// securityElem.setAttribute("SOAP-ENV:mustUnderstand", "1");
//
//			SOAPElement usernameTokenElem = securityElem.addChildElement("UsernameToken", "wsse");
//
//			SOAPElement usernameElem = usernameTokenElem.addChildElement("Username", "wsse");
//			usernameElem.setTextContent(onvifDevice.getUsername());
//
//			SOAPElement passwordElem = usernameTokenElem.addChildElement("Password", "wsse");
//			passwordElem.setAttribute("Type", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest");
//			passwordElem.setTextContent(encrypedPassword);
//
//			SOAPElement nonceElem = usernameTokenElem.addChildElement("Nonce", "wsse");
//			nonceElem.setAttribute("EncodingType", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary");
//			nonceElem.setTextContent(onvifDevice.getEncryptedNonce());
//
//			SOAPElement createdElem = usernameTokenElem.addChildElement("Created", "wsu");
//			createdElem.setTextContent(onvifDevice.getLastUTCTime());
//		}
//	}

	
}
