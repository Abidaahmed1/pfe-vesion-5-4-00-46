package com.gestionStock_backend_mobile.repository.Stock;

import com.gestionStock_backend_mobile.entity.Stock.LigneInventaire;
import com.gestionStock_backend_mobile.entity.Stock.LigneStatut;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface LigneInventaireRepository extends JpaRepository<LigneInventaire, Long> {
    List<LigneInventaire> findByInventaireId(Long inventaireId);

    long countByInventaireIdAndStatutLigne(Long inventaireId, LigneStatut statutLigne);

    long countByInventaireId(Long inventaireId);

    java.util.Optional<LigneInventaire> findByInventaireIdAndPieceId(Long inventaireId, Long pieceId);

    List<LigneInventaire> findByInventaireIdAndResponsableLogistiqueId(Long inventaireId,
            String responsableLogistiqueId);

    java.util.Optional<LigneInventaire> findByInventaireIdAndPieceIdAndResponsableLogistiqueId(Long inventaireId,
            Long pieceId, String responsableLogistiqueId);
}
