package com.gestionStock_backend_mobile.entity.Stock;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonBackReference;
import com.gestionStock_backend_mobile.entity.piece.PieceDetachee;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "inventaire_details")
public class LigneInventaire {
    @Id
    @SequenceGenerator(name = "inventaire_details_seq", sequenceName = "inventaire_details_id_seq", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "inventaire_details_seq")
    private Long id;

    private Integer stockPhysique;
    private Integer stockTheorique;
    private LocalDateTime dateScan;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "statut_ligne", columnDefinition = "VARCHAR(50)")
    private LigneStatut statutLigne = LigneStatut.A_SCANNER;

    @Builder.Default
    @Column(name = "est_valide", nullable = false)
    private boolean estValide = false;

    private String justification;
    @ManyToOne(cascade = { CascadeType.MERGE })
    @JoinColumn(name = "piece_id", nullable = true)
    private PieceDetachee piece;

    @ManyToOne
    @JoinColumn(name = "inventaire_id", nullable = false)
    @JsonBackReference
    private Inventaire inventaire;

    @Column(name = "responsable_logistique_id")
    private String responsableLogistiqueId;
}
