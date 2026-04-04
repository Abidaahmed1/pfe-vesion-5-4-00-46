package com.gestionStock_backend_mobile.repository.user;

import com.gestionStock_backend_mobile.entity.user.User;
import com.gestionStock_backend_mobile.entity.user.Role;
import com.gestionStock_backend_mobile.entity.entreprise.Entreprise;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.List;

public interface UserRepository extends JpaRepository<User, String> {
    Optional<User> findByEmail(String email);
    List<User> findByRoleIn(List<Role> roles);
    List<User> findByRoleInAndEntreprise(List<Role> roles, Entreprise entreprise);
}
