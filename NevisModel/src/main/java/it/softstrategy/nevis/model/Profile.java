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
 * The persistent class for the "profile" database table.
 * 
 */
// @Entity
// @Table(name="profile")
// @NamedQuery(name="Profile.findAll", query="SELECT p FROM Profile p")
public class Profile implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Float framerate;
	private Long id;
	private String profileName;
	private String resolution;

	public Profile() {
	}


	// @Column(name="framerate")
	public Float getFramerate() {
		return this.framerate;
	}

	public void setFramerate(Float framerate) {
		this.framerate = framerate;
	}


	// @Id
	// @GeneratedValue(strategy=GenerationType.AUTO)
	// @Column(name="id_profile")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}


	// @Column(name="profile_name")
	public String getProfileName() {
		return this.profileName;
	}

	public void setProfileName(String profileName) {
		this.profileName = profileName;
	}


	// @Column(name="resolution")
	public String getResolution() {
		return this.resolution;
	}

	public void setResolution(String resolution) {
		this.resolution = resolution;
	}

}