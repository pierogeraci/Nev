package it.softstrategy.nevis.model;

import java.io.Serializable;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQuery;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import java.util.Date;


/**
 * The persistent class for the "cam" database table.
 * 
 */
//////@Entity
//// @Table(name="cam")
//// @NamedQuery(name="Camera.findAll", query="SELECT c FROM Camera c")
public class Camera implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Date firstSeen;
	private Integer httpPort;
	private Long id;
	private Integer inputConnectors;
	private String ipAddress;
	private Boolean isManual;
	private Boolean isOnvif;
	private Date lastSeen;
	private String macAddress;
	private String model;
	private String vendor;

	public Camera() {
	}


//	// @Temporal(TemporalType.TIMESTAMP)
//	// @Column(name="first_seen")
	public Date getFirstSeen() {
		return this.firstSeen;
	}

	public void setFirstSeen(Date firstSeen) {
		this.firstSeen = firstSeen;
	}


//	// @Column(name="http_port")
	public Integer getHttpPort() {
		return this.httpPort;
	}

	public void setHttpPort(Integer httpPort) {
		this.httpPort = httpPort;
	}


//	// @Id
//	// @GeneratedValue(strategy=GenerationType.AUTO)
//	// @Column(name="id_cam")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}


//	// @Column(name="input_connectors")
	public Integer getInputConnectors() {
		return this.inputConnectors;
	}

	public void setInputConnectors(Integer inputConnector) {
		this.inputConnectors = inputConnector;
	}

//	// @Column(name="ip_address")
	public String getIpAddress() {
		return this.ipAddress;
	}

	public void setIpAddress(String ipAddress) {
		this.ipAddress = ipAddress;
	}


//	// @Column(name="is_manual")
	public Boolean getIsManual() {
		return this.isManual;
	}

	public void setIsManual(Boolean isManual) {
		this.isManual = isManual;
	}


//	// @Column(name="is_onvif")
	public Boolean getIsOnvif() {
		return this.isOnvif;
	}

	public void setIsOnvif(Boolean isOnvif) {
		this.isOnvif = isOnvif;
	}


//	// @Temporal(TemporalType.TIMESTAMP)
//	// @Column(name="last_seen")
	public Date getLastSeen() {
		return this.lastSeen;
	}

	public void setLastSeen(Date lastSeen) {
		this.lastSeen = lastSeen;
	}


//	// @Column(name="mac_address")
	public String getMacAddress() {
		return this.macAddress;
	}

	public void setMacAddress(String macAddress) {
		this.macAddress = macAddress;
	}


//	// @Column(name="model")
	public String getModel() {
		return this.model;
	}

	public void setModel(String model) {
		this.model = model;
	}


//	// @Column(name="vendor")
	public String getVendor() {
		return this.vendor;
	}

	public void setVendor(String vendor) {
		this.vendor = vendor;
	}

}