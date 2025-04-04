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
 * The persistent class for the "file_recording" database table.
 * 
 */
// @Entity
// @Table(name="file_recording")
// @NamedQuery(name="FileRecording.findAll", query="SELECT f FROM FileRecording f")
public class FileRecording implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private String bitRateMedium;
	private Date dateCreation;
	private String fileName;
	private String fileSize;
	private Long id;
	private Long idSlot;
	private String slotFolder;
	private String streamUrl;

	public FileRecording() {
	}


	// @Column(name="bit_rate_medium")
	public String getBitRateMedium() {
		return this.bitRateMedium;
	}

	public void setBitRateMedium(String bitRateMedium) {
		this.bitRateMedium = bitRateMedium;
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="date_creation")
	public Date getDateCreation() {
		return this.dateCreation;
	}

	public void setDateCreation(Date dateCreation) {
		this.dateCreation = dateCreation;
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


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_file_recording")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}


	// @Column(name="id_slot")
	public Long getIdSlot() {
		return this.idSlot;
	}

	public void setIdSlot(Long idSlot) {
		this.idSlot = idSlot;
	}


	// @Column(name="slot_folder")
	public String getSlotFolder() {
		return this.slotFolder;
	}

	public void setSlotFolder(String slotFolder) {
		this.slotFolder = slotFolder;
	}


	// @Column(name="stream_url")
	public String getStreamUrl() {
		return this.streamUrl;
	}

	public void setStreamUrl(String streamUrl) {
		this.streamUrl = streamUrl;
	}

}