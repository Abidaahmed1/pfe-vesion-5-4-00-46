package com.gestionStock_backend_mobile.entity.Stock;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import com.fasterxml.jackson.annotation.JsonManagedReference;

@Builder
@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "inventaires")
public class Inventaire {
    @Id
    @SequenceGenerator(name = "inventaires_seq", sequenceName = "inventaires_id_seq", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "inventaires_seq")
    private Long id;

    private Long entrepriseId;
    private LocalDateTime date;
    private String nom;
    private boolean estValide;
    private boolean estTermine;

    @Column(name = "createur_id")
    private String createurId;

    @Column(name = "heure_debut_effective")
    private LocalDateTime heureDebutEffective;

    @OneToMany(mappedBy = "inventaire", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference
    @Builder.Default
    private List<LigneInventaire> lignes = new ArrayList<>();
}
