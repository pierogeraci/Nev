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
 * The persistent class for the "log_engine" database table.
 * 
 */
// @Entity
// @Table(name="log_engine")
// @NamedQuery(name="LogEngine.findAll", query="SELECT l FROM LogEngine l")
public class LogEngine implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Date dateUpdate;
	private Long id;
	private String message;
	private String type;

	public LogEngine() {
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="date_update")
	public Date getDateUpdate() {
		return this.dateUpdate;
	}

	public void setDateUpdate(Date dateUpdate) {
		this.dateUpdate = dateUpdate;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_log_engine")
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


	// @Column(name="type")
	public String getType() {
		return this.type;
	}

	public void setType(String type) {
		this.type = type;
	}

}