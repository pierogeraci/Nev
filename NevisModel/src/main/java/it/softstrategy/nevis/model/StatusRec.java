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
 * The persistent class for the "status_rec" database table.
 * 
 */
// @Entity
// @Table(name="status_rec")
// @NamedQuery(name="StatusRec.findAll", query="SELECT s FROM StatusRec s")
public class StatusRec implements Serializable {
	private static final long serialVersionUID = 1L;
	private Long id;
	private String name;

	public StatusRec() {
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_status_rec")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}


	// @Column(name="name")
	public String getName() {
		return this.name;
	}

	public void setName(String name) {
		this.name = name;
	}

}