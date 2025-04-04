package it.softstrategy.nevis.model;

import java.io.Serializable;

import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.JoinTable;
import javax.persistence.ManyToMany;
import javax.persistence.NamedQuery;
import javax.persistence.OneToOne;
import javax.persistence.Table;
import javax.persistence.Transient;

import org.hibernate.validator.constraints.Email;
import org.hibernate.validator.constraints.Length;
import org.hibernate.validator.constraints.NotEmpty;


/**
 * The persistent class for the "user" database table.
 * 
 */
@Entity
@Table(name="user")
@NamedQuery(name="User.findAll", query="SELECT u FROM User u")
public class User implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private Boolean active;
	private String email;
	private String lastName;
	private String name;
	private String password;
	private Long id;
	private Set<Role> roles;
	
	
//	private UserAttempts userAttempts;
	

	public User() {
	}
	
	@Id
	@GeneratedValue(strategy=GenerationType.AUTO)
	@Column(name="user_id")
	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}


	@Column(name="active")
	public Boolean getActive() {
		return this.active;
	}

	public void setActive(Boolean active) {
		this.active = active;
	}


	@Column(name="email")
	@Email(message = "*Please provide a valid Email")
	@NotEmpty(message = "*Please provide an email")
	public String getEmail() {
		return this.email;
	}

	public void setEmail(String email) {
		this.email = email;
	}


	@Column(name="last_name")
	@NotEmpty(message = "*Please provide your last name")
	public String getLastName() {
		return this.lastName;
	}

	public void setLastName(String lastName) {
		this.lastName = lastName;
	}


	@Column(name="name")
	@NotEmpty(message = "*Please provide your name")
	public String getName() {
		return this.name;
	}

	public void setName(String name) {
		this.name = name;
	}


	@Column(name="password")
	@Length(min = 5, message = "*Your password must have at least 5 characters")
	@NotEmpty(message = "*Please provide your password")
	//@Transient
	public String getPassword() {
		return this.password;
	}

	public void setPassword(String password) {
		this.password = password;
	}


	//many-to-many association to Role
	@ManyToMany(cascade = CascadeType.ALL)
	@JoinTable(
		name="user_role"
		, joinColumns= @JoinColumn(name = "user_id")
		, inverseJoinColumns=@JoinColumn(name = "role_id")
		)
	public Set<Role> getRoles() {
		return this.roles;
	}

	public void setRoles(Set<Role> roles) {
		this.roles = roles;
	}

//	@OneToOne(mappedBy = "user", cascade = CascadeType.ALL,
//            fetch = FetchType.LAZY, optional = false)
//	public UserAttempts getUserAttempts() {
//		return userAttempts;
//	}

//	public void setUserAttempts(UserAttempts userAttempts) {
//		if (userAttempts == null) {
//			if (this.userAttempts != null) {
//				this.userAttempts.setUser(null);
//			}
//		} else {
//			userAttempts.setUser(this);
//		}
//		this.userAttempts = userAttempts;
//	}
	
	

}