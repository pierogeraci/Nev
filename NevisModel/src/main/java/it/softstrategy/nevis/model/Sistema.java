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
 * The persistent class for the "sistema" database table.
 * 
 */
// @Entity
// @Table(name="sistema")
// @NamedQuery(name="Sistema.findAll", query="SELECT s FROM Sistema s")
public class Sistema implements Serializable {
	private static final long serialVersionUID = 1L;
	private String chiave;
	private Long id;
	private String sezione;
	private String valore;

	public Sistema() {
	}


	// @Column(name="chiave")
	public String getChiave() {
		return this.chiave;
	}

	public void setChiave(String chiave) {
		this.chiave = chiave;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_sistema")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}


	// @Column(name="sezione")
	public String getSezione() {
		return this.sezione;
	}

	public void setSezione(String sezione) {
		this.sezione = sezione;
	}


	// @Column(name="valore")
	public String getValore() {
		return this.valore;
	}

	public void setValore(String valore) {
		this.valore = valore;
	}

}