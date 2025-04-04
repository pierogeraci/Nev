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
 * The persistent class for the "server_history" database table.
 * 
 */
// @Entity
// @Table(name="server_history")
// @NamedQuery(name="ServerHistory.findAll", query="SELECT s FROM ServerHistory s")
public class ServerHistory implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Date dateUpdate;
	private String hostName;
	private Long id;
	private String ipAddress;

	public ServerHistory() {
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="date_update")
	public Date getDateUpdate() {
		return this.dateUpdate;
	}

	public void setDateUpdate(Date dateUpdate) {
		this.dateUpdate = dateUpdate;
	}


	// @Column(name="host_name")
	public String getHostName() {
		return this.hostName;
	}

	public void setHostName(String hostName) {
		this.hostName = hostName;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_server_history")
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

}