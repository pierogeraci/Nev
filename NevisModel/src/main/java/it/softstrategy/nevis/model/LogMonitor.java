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
 * The persistent class for the "log_monitor" database table.
 * 
 */
// @Entity
// @Table(name="log_monitor")
// @NamedQuery(name="LogMonitor.findAll", query="SELECT l FROM LogMonitor l")
public class LogMonitor implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Long id;
	private String message;
	private Date timestamp;
	private String type;

	public LogMonitor() {
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_log_monitor")
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


	// @Temporal(TemporalType.DATE)
	// @Column(name="timestamp")
	public Date getTimestamp() {
		return this.timestamp;
	}

	public void setTimestamp(Date timestamp) {
		this.timestamp = timestamp;
	}


	// @Column(name="type")
	public String getType() {
		return this.type;
	}

	public void setType(String type) {
		this.type = type;
	}

}