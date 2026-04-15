package com.gestionStock_backend_mobile.repository.piece;

import com.gestionStock_backend_mobile.entity.piece.PieceDetachee;
import com.gestionStock_backend_mobile.entity.entreprise.Entreprise;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface PieceDetacheeRepository extends JpaRepository<PieceDetachee, Long> {
    // Optional<PieceDetachee> findByCodeBarre(String codeBarre);
    Optional<PieceDetachee> findByCodeBarreAndEntreprise(String codeBarre, Entreprise entreprise);

    java.util.List<PieceDetachee> findByEntreprise(Entreprise entreprise);

    java.util.List<PieceDetachee> findByEntrepriseAndArchiveeFalse(Entreprise entreprise);

    @Query("SELECT p FROM PieceDetachee p WHERE p.entreprise = :entreprise AND (p.archivee IS NULL OR p.archivee = false)")
    java.util.List<PieceDetachee> findActiveByEntreprise(@Param("entreprise") Entreprise entreprise);
}
