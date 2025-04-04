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
 * The persistent class for the "log_recorder" database table.
 * 
 */
// @Entity
// @Table(name="log_recorder")
// @NamedQuery(name="LogRecorder.findAll", query="SELECT l FROM LogRecorder l")
public class LogRecorder implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private String bitRate;
	private Date dateUpdate;
	private String duration;
	private String fileName;
	private String fileSize;
	private String macAddress;
	private Long idLogRecorder;
	private String folderName;
	private String type;
	private String slotName;

	public LogRecorder() {
	}


	// @Column(name="bit_rate")
	public String getBitRate() {
		return this.bitRate;
	}

	public void setBitRate(String bitRate) {
		this.bitRate = bitRate;
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="date_update")
	public Date getDateUpdate() {
		return this.dateUpdate;
	}

	public void setDateUpdate(Date dateUpdate) {
		this.dateUpdate = dateUpdate;
	}


	// @Column(name="duration")
	public String getDuration() {
		return this.duration;
	}

	public void setDuration(String duration) {
		this.duration = duration;
	}


	// @Column(name="file_name")
	public String getFileName() {
		return this.fileName;
	}

	public void setFileName(String fileName) {
		this.fileName = fileName;
	}


	// @Column(name="file_size")
	public String getFileSize() {
		return this.fileSize;
	}

	public void setFileSize(String fileSize) {
		this.fileSize = fileSize;
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
	// @Column(name="id_log_recorder")
	public Long getIdLogRecorder() {
		return this.idLogRecorder;
	}

	public void setIdLogRecorder(Long idLogRecorder) {
		this.idLogRecorder = idLogRecorder;
	}


	// @Column(name="folder_name")
	public String getFolderName() {
		return this.folderName;
	}

	public void setFolderName(String folderName) {
		this.folderName = folderName;
	}

	// @Column(name="slot_name")
	public String getSlotName() {
		return slotName;
	}


	public void setSlotName(String slotName) {
		this.slotName = slotName;
	}


	// @Column(name="type")
	public String getType() {
		return this.type;
	}

	public void setType(String type) {
		this.type = type;
	}

}