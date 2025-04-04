package it.softstrategy.nevis.model;

import java.io.Serializable;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQuery;
import javax.persistence.Table;



/**
 * The persistent class for the "recording" database table.
 * 
 */
// @Entity
// @Table(name="recording")
// @NamedQuery(name="Recording.findAll", query="SELECT r FROM Recording r")
public class Recording implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Long idCamera;
	private Long idCameraTemplate;
	private Long id;
	private Long idSlot;
	private Long idStatus;
	private Integer pid;
	private String slotFolder;
	private String streamUrl;

	public Recording() {
	}


	// @Column(name="id_cams")
	public Long getIdCamera() {
		return this.idCamera;
	}

	public void setIdCamera(Long idCamera) {
		this.idCamera = idCamera;
	}


	// @Column(name="id_cams_template")
	public Long getIdCameraTemplate() {
		return this.idCameraTemplate;
	}

	public void setIdCameraTemplate(Long idCameraTemplate) {
		this.idCameraTemplate = idCameraTemplate;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_recording")
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


	// @Column(name="id_status")
	public Long getIdStatus() {
		return this.idStatus;
	}

	public void setIdStatus(Long idStatus) {
		this.idStatus = idStatus;
	}


	// @Column(name="pid")
	public Integer getPid() {
		return this.pid;
	}

	public void setPid(Integer pid) {
		this.pid = pid;
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