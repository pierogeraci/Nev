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
 * The persistent class for the "file_recording_history_async" database table.
 * 
 */
// @Entity
// @Table(name="file_recording_history_async")
// @NamedQuery(name="FileRecordingHistoryAsync.findAll", query="SELECT f FROM FileRecordingHistoryAsync f")
public class FileRecordingHistoryAsync implements Serializable {
	private static final long serialVersionUID = 1L;
	private Date dateCreation;
	private Date endDate;
	private String fileName;
	private Long idFileRecordingHistoryAsync;
	private Long idSlot;
	private Long idUser;
	private String slotFolder;
	private Date startDate;

	public FileRecordingHistoryAsync() {
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="date_creation")
	public Date getDateCreation() {
		return this.dateCreation;
	}

	public void setDateCreation(Date dateCreation) {
		this.dateCreation = dateCreation;
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="end_date")
	public Date getEndDate() {
		return this.endDate;
	}

	public void setEndDate(Date endDate) {
		this.endDate = endDate;
	}


	// @Column(name="file_name")
	public String getFileName() {
		return this.fileName;
	}

	public void setFileName(String fileName) {
		this.fileName = fileName;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_file_recording_history_async")
	public Long getIdFileRecordingHistoryAsync() {
		return this.idFileRecordingHistoryAsync;
	}

	public void setIdFileRecordingHistoryAsync(Long idFileRecordingHistoryAsync) {
		this.idFileRecordingHistoryAsync = idFileRecordingHistoryAsync;
	}


	// @Column(name="id_slot")
	public Long getIdSlot() {
		return this.idSlot;
	}

	public void setIdSlot(Long idSlot) {
		this.idSlot = idSlot;
	}


	// @Column(name="id_user")
	public Long getIdUser() {
		return this.idUser;
	}

	public void setIdUser(Long idUser) {
		this.idUser = idUser;
	}


	// @Column(name="slot_folder")
	public String getSlotFolder() {
		return this.slotFolder;
	}

	public void setSlotFolder(String slotFolder) {
		this.slotFolder = slotFolder;
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="start_date")
	public Date getStartDate() {
		return this.startDate;
	}

	public void setStartDate(Date startDate) {
		this.startDate = startDate;
	}

}