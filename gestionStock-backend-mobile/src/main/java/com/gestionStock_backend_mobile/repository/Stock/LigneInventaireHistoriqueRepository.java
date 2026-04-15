package com.gestionStock_backend_mobile.repository.Stock;

import com.gestionStock_backend_mobile.entity.Stock.LigneInventaireHistorique;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LigneInventaireHistoriqueRepository extends JpaRepository<LigneInventaireHistorique, Long> {
}
