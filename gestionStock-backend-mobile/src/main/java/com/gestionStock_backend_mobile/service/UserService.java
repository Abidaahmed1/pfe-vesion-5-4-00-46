package com.gestionStock_backend_mobile.service;

import com.gestionStock_backend_mobile.entity.entreprise.Entreprise;
import com.gestionStock_backend_mobile.entity.user.User;
import com.gestionStock_backend_mobile.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    public Optional<User> getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Jwt jwt) {
            String userId = jwt.getSubject();
            Optional<User> user = userRepository.findById(userId);

            if (user.isEmpty()) {
                String email = jwt.getClaimAsString("email");
                if (email != null) {
                    user = userRepository.findByEmail(email);
                }
            }
            return user;
        }
        return Optional.empty();
    }

    public Entreprise getCurrentUserEntreprise() {
        return getCurrentUser().map(User::getEntreprise).orElse(null);
    }

    public String getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Jwt jwt) {
            return jwt.getSubject();
        }
        return null;
    }
}
