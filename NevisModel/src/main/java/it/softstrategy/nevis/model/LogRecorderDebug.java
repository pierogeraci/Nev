package it.softstrategy.nevis.model;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Lob;
import javax.persistence.NamedQuery;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import java.util.Date;


/**
 * The persistent class for the "log_recorder_debug" database table.
 * 
 */
// @Entity
// @Table(name="log_recorder_debug")
// @NamedQuery(name="LogRecorderDebug.findAll", query="SELECT l FROM LogRecorderDebug l")
public class LogRecorderDebug implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Date dateUpdate;
	private String macAddress;
	private Long id;
	private String message;
	private String folderName;
	private String type;
	private String slotName;

	public LogRecorderDebug() {
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="date_update")
	public Date getDateUpdate() {
		return this.dateUpdate;
	}

	public void setDateUpdate(Date dateUpdate) {
		this.dateUpdate = dateUpdate;
	}


	// @Column(name="mac_address")
	public String getMacAddress() {
		return this.macAddress;
	}

	public void setMacAddress(String macAddress) {
		this.macAddress = macAddress;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_log_recorder_debug")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	// @Lob
	// @Basic
	// @Column(name="message")
	public String getMessage() {
		return this.message;
	}

	public void setMessage(String message) {
		this.message = message;
	}


	// @Column(name="folder_name")
	public String getFolderName() {
		return this.folderName;
	}

	public void setFolderName(String folderName) {
		this.folderName = folderName;
	}


	// @Column(name="type")
	public String getType() {
		return this.type;
	}

	public void setType(String type) {
		this.type = type;
	}


	// @Column(name = "slot_name")
	public String getSlotName() {
		return slotName;
	}


	public void setSlotName(String slotName) {
		this.slotName = slotName;
	}

}