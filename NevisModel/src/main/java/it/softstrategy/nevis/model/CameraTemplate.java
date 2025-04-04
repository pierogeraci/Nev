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
 * The persistent class for the "cam_template" database table.
 * 
 */
// @Entity
// @Table(name="cam_template")
// @NamedQuery(name="CameraTemplate.findAll", query="SELECT c FROM CameraTemplate c")
public class CameraTemplate implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private String alias;
	private Long id;
	private Long idProfile;
	private String model;
	private String urlTemplate;
	private String vendor;

	public CameraTemplate() {
	}


	// @Column(name="alias")
	public String getAlias() {
		return this.alias;
	}

	public void setAlias(String alias) {
		this.alias = alias;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_cam_template")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}


	// @Column(name="id_profile")
	public Long getIdProfile() {
		return this.idProfile;
	}

	public void setIdProfile(Long idProfile) {
		this.idProfile = idProfile;
	}


	// @Column(name="model")
	public String getModel() {
		return this.model;
	}

	public void setModel(String model) {
		this.model = model;
	}


	// @Column(name="url_template")
	public String getUrlTemplate() {
		return this.urlTemplate;
	}

	public void setUrlTemplate(String urlTemplate) {
		this.urlTemplate = urlTemplate;
	}


	// @Column(name="vendor")
	public String getVendor() {
		return this.vendor;
	}

	public void setVendor(String vendor) {
		this.vendor = vendor;
	}

}