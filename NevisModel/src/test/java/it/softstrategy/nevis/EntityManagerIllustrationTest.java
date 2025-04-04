package it.softstrategy.nevis;


import java.util.HashSet;
import java.util.Set;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.Persistence;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import it.softstrategy.nevis.model.Role;
import it.softstrategy.nevis.model.User;

public class EntityManagerIllustrationTest {
	
	private EntityManagerFactory entityManagerFactory;

	@Before
	public void setUp() throws Exception {
		// like discussed with regards to SessionFactory, 
		//an EntityManagerFactory is set up once for an application
		// 		IMPORTANT: notice how the name here matches the name we gave the persistence-unit in persistence.xml!
		entityManagerFactory = Persistence.createEntityManagerFactory("it.softstrategy.nevis.model");
	}

	@After
	public void tearDown() throws Exception {
		if (entityManagerFactory != null) {
			entityManagerFactory.close();
		}
	}

	@Test
	public void test() {
		EntityManager entityManager = entityManagerFactory.createEntityManager();
		entityManager.getTransaction() .begin();
		
//		Camera cam1 = new Camera();
//		cam1.setIpAddress("10.28.0.52");
//		cam1.setVendor("axis");
//		cam1.setModel("p3409");
//		entityManager.persist(cam1);
		
		User u1 = new User();
		u1.setEmail("email@email.it");
		u1.setName("Test");
		u1.setLastName("Test");
		u1.setActive(Boolean.TRUE);
		u1.setPassword("password");
		Role r1 = new Role();
		r1.setRole("admin");
		Set<Role> roles = new HashSet<>();
		roles.add(r1);
		u1.setRoles(roles);
		entityManager.persist(u1);
		
		
		entityManager.getTransaction().commit();
		entityManager.close();
	}

}
