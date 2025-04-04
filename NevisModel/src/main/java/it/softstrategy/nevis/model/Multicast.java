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
 * The persistent class for the "multicast" database table.
 * 
 */
// @Entity
// @Table(name="multicast")
// @NamedQuery(name="Multicast.findAll", query="SELECT m FROM Multicast m")
public class Multicast implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Date expired;
	private Long id;
	private String idSession;
	private String slotName;
	private Long idUser;
	private String ipAddress;
	private String model;
	private Integer portNumber;
	private Date startDate;
	private Boolean active;
	private String vendor;

	public Multicast() {
	}


	// @Column(name="expired")
	// @Temporal(TemporalType.DATE)
	public Date getExpired() {
		return this.expired;
	}

	public void setExpired(Date expired) {
		this.expired = expired;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_multicast")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}


	// @Column(name="id_session")
	public String getIdSession() {
		return this.idSession;
	}

	public void setIdSession(String idSession) {
		this.idSession = idSession;
	}


	// @Column(name="id_slot")
	public String getSlotName() {
		return this.slotName;
	}

	public void setSlotName(String slotName) {
		this.slotName = slotName;
	}


	// @Column(name="id_user")
	public Long getIdUser() {
		return this.idUser;
	}

	public void setIdUser(Long idUser) {
		this.idUser = idUser;
	}


	// @Column(name="ip_address")
	public String getIpAddress() {
		return this.ipAddress;
	}

	public void setIpAddress(String ipAddress) {
		this.ipAddress = ipAddress;
	}


	// @Column(name="model")
	public String getModel() {
		return this.model;
	}

	public void setModel(String model) {
		this.model = model;
	}


	// @Column(name="port_number")
	public Integer getPortNumber() {
		return this.portNumber;
	}

	public void setPortNumber(Integer portNumber) {
		this.portNumber = portNumber;
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="start_date")
	public Date getStartDate() {
		return this.startDate;
	}

	public void setStartDate(Date startDate) {
		this.startDate = startDate;
	}

	// @Column(name="active")
	public Boolean getActive() {
		return active;
	}


	public void setActive(Boolean active) {
		this.active = active;
	}


	// @Column(name="vendor")
	public String getVendor() {
		return this.vendor;
	}

	public void setVendor(String vendor) {
		this.vendor = vendor;
	}

}