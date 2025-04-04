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
 * The persistent class for the "log_session" database table.
 * 
 */
// @Entity
// @Table(name="log_session")
// @NamedQuery(name="LogSession.findAll", query="SELECT l FROM LogSession l")
public class LogSession implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private String actionName;
	private Date dateUpdate;
	private String description;
	private String functionName;
	private Long id;
	private String idSession;
	private Long idUser;

	public LogSession() {
	}


	// @Column(name="action_name")
	public String getActionName() {
		return this.actionName;
	}

	public void setActionName(String actionName) {
		this.actionName = actionName;
	}


	// @Temporal(TemporalType.DATE)
	// @Column(name="date_update")
	public Date getDateUpdate() {
		return this.dateUpdate;
	}

	public void setDateUpdate(Date dateUpdate) {
		this.dateUpdate = dateUpdate;
	}


	// @Column(name="description")
	public String getDescription() {
		return this.description;
	}

	public void setDescription(String description) {
		this.description = description;
	}


	// @Column(name="function_name")
	public String getFunctionName() {
		return this.functionName;
	}

	public void setFunctionName(String functionName) {
		this.functionName = functionName;
	}


	// @Id
	// // @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_log_session")
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


	// @Column(name="id_user")
	public Long getIdUser() {
		return this.idUser;
	}

	public void setIdUser(Long idUser) {
		this.idUser = idUser;
	}

}