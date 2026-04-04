package com.gestionStock_backend_mobile.entity.user;

import com.gestionStock_backend_mobile.entity.entreprise.Entreprise;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {
    @Id
    private String id; // Keycloak sub (subject)

    private String firstName;
    private String lastName;
    private String email;

    @Enumerated(EnumType.STRING)
    private Role role;

    @ManyToOne
    @JoinColumn(name = "entreprise_id")
    private Entreprise entreprise;

    @Builder.Default
    private boolean active = true;
}
