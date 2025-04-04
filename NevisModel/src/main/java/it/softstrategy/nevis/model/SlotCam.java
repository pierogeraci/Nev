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
 * The persistent class for the "slot_cam" database table.
 * 
 */
// @Entity
// @Table(name="slot_cam")
// @NamedQuery(name="SlotCam.findAll", query="SELECT s FROM SlotCam s")
public class SlotCam implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Date dateUpdate;
	private Long idSlot;
	private Long id;
	private String ipAddress;
	private String macAddress;

	public SlotCam() {
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="date_update")
	public Date getDateUpdate() {
		return this.dateUpdate;
	}

	public void setDateUpdate(Date dateUpdate) {
		this.dateUpdate = dateUpdate;
	}


	// @Column(name="id_slot")
	public Long getIdSlot() {
		return this.idSlot;
	}

	public void setIdSlot(Long idSlot) {
		this.idSlot = idSlot;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_slot_cam")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}


	// @Column(name="ip_address")
	public String getIpAddress() {
		return this.ipAddress;
	}

	public void setIpAddress(String ipAddress) {
		this.ipAddress = ipAddress;
	}


	// @Column(name="mac_address")
	public String getMacAddress() {
		return this.macAddress;
	}

	public void setMacAddress(String macAddress) {
		this.macAddress = macAddress;
	}

}