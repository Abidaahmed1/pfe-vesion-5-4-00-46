package com.gestionStock_backend_mobile.repository.Stock;

import com.gestionStock_backend_mobile.entity.Stock.Inventaire;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface InventaireRepository extends JpaRepository<Inventaire, Long> {
    Optional<Inventaire> findFirstByEstTermineFalseOrderByDateDesc();

    @Query("SELECT i FROM Inventaire i WHERE i.estTermine = false AND i.entrepriseId = :enterpriseId ORDER BY i.date DESC LIMIT 1")
    Optional<Inventaire> findLatestActiveForEnterprise(@Param("enterpriseId") Long enterpriseId);
}
