package com.gestionStock_backend_mobile.entity.piece;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DetailPiece {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JsonBackReference("piece_details")
    @ManyToOne
    @JoinColumn(name = "piece_id")
    private PieceDetachee piece;

    @ManyToOne
    @JoinColumn(name = "parametre_id")
    private com.gestionStock_backend_mobile.entity.parametre.Parametre parametre;

    private String valeur;
}
