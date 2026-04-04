package com.gestionStock_backend_mobile.controller;

import com.gestionStock_backend_mobile.entity.entreprise.Entreprise;
import com.gestionStock_backend_mobile.repository.piece.PieceDetacheeRepository;
import com.gestionStock_backend_mobile.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/mobile/pieces")
@RequiredArgsConstructor
@CrossOrigin("*")
public class PieceMobileController {

    private final PieceDetacheeRepository pieceDetacheeRepository;
    private final UserService userService;

    @GetMapping("/info")
    public ResponseEntity<?> getPieceInfo(@RequestParam String barcode) {
        Entreprise entreprise = userService.getCurrentUserEntreprise();
        if (entreprise == null) {
            return ResponseEntity.status(403).body(Map.of("message", "Utilisateur non rattaché à une entreprise"));
        }

        return pieceDetacheeRepository.findByCodeBarreAndEntreprise(barcode, entreprise)
                .map(piece -> {
                    Map<String, Object> data = new HashMap<>();
                    data.put("id", piece.getId());
                    data.put("reference", piece.getReference());
                    data.put("designation", piece.getDesignation());
                    data.put("nom", piece.getDesignation());
                    data.put("quantite", piece.getQuantite());
                    data.put("codeBarre", piece.getCodeBarre());
                    data.put("imageUrl", piece.getImageUrl());
                    data.put("archivee", piece.getArchivee() != null ? piece.getArchivee() : false);

                    if (piece.getDetails() != null) {
                        data.put("details", piece.getDetails().stream().map(d -> {
                            Map<String, String> detailMap = new HashMap<>();
                            detailMap.put("nom", d.getParametre() != null ? d.getParametre().getNom() : "Inconnu");
                            detailMap.put("valeur", d.getValeur());
                            return detailMap;
                        }).toList());
                    }

                    return ResponseEntity.ok(data);
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
