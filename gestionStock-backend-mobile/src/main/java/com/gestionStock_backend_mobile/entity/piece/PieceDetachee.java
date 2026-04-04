package com.gestionStock_backend_mobile.entity.piece;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.gestionStock_backend_mobile.entity.entreprise.Entreprise;
import jakarta.persistence.*;
import lombok.*;
import java.util.List;
import java.util.ArrayList;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "piece_detachee")
public class PieceDetachee {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "entreprise_id")
    private Entreprise entreprise;

    private String reference;
    private String designation;

    @Column(name = "code_barre")
    private String codeBarre;

    @Column(columnDefinition = "TEXT")
    private String imageUrl;

    @Column(name = "quantite")
    private Integer quantite;

    @Column(name = "archivee")
    private Boolean archivee;

    @JsonManagedReference("piece_details")
    @OneToMany(mappedBy = "piece", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<DetailPiece> details = new ArrayList<>();
}
