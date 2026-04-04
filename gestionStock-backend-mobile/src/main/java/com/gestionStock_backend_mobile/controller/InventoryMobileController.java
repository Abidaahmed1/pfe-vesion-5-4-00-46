package com.gestionStock_backend_mobile.controller;

import com.gestionStock_backend_mobile.entity.Stock.Inventaire;
import com.gestionStock_backend_mobile.entity.Stock.LigneInventaire;
import com.gestionStock_backend_mobile.entity.Stock.LigneStatut;
import com.gestionStock_backend_mobile.repository.Stock.InventaireRepository;
import com.gestionStock_backend_mobile.repository.Stock.LigneInventaireRepository;
import com.gestionStock_backend_mobile.repository.piece.PieceDetacheeRepository;
import com.gestionStock_backend_mobile.entity.entreprise.Entreprise;
import com.gestionStock_backend_mobile.entity.piece.PieceDetachee;
import com.gestionStock_backend_mobile.entity.notification.NotificationType;
import com.gestionStock_backend_mobile.entity.user.Role;
import com.gestionStock_backend_mobile.service.UserService;
import com.gestionStock_backend_mobile.service.notification.NotificationService;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/mobile/inventaires")
@RequiredArgsConstructor
@CrossOrigin("*")
public class InventoryMobileController {

    private final InventaireRepository inventaireRepository;
    private final LigneInventaireRepository ligneInventaireRepository;
    private final PieceDetacheeRepository pieceDetacheeRepository;
    private final UserService userService;
    private final NotificationService notificationService;

    @GetMapping("/active")
    public ResponseEntity<Map<String, Object>> getActiveInventory() {
        Entreprise entreprise = userService.getCurrentUserEntreprise();
        if (entreprise == null) {
            return ResponseEntity.status(403).build();
        }

        return inventaireRepository.findLatestActiveForEnterprise(entreprise.getId())
                .map(inv -> {
                    Map<String, Object> data = new HashMap<>();
                    data.put("id", inv.getId());
                    data.put("nom", inv.getNom());
                    data.put("date", inv.getDate());
                    return ResponseEntity.ok(data);
                })
                .orElse(ResponseEntity.noContent().build());
    }

    @GetMapping("/{id}/stats")
    public ResponseEntity<Map<String, Object>> getStats(@PathVariable Long id) {
        String userId = userService.getCurrentUserId();
        if (userId == null)
            return ResponseEntity.status(401).build();

        long total = ligneInventaireRepository.countByInventaireId(id);
        long scanned = ligneInventaireRepository.countByInventaireIdAndStatutLigne(id, LigneStatut.EN_ATTENTE_AUDIT);

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalPieces", total);
        stats.put("scannedPieces", scanned);
        stats.put("progress", total == 0 ? 0 : (double) scanned / total);
        stats.put("lastScan", LocalDateTime.now());

        return ResponseEntity.ok(stats);
    }

    @GetMapping("/{id}/lignes")
    public ResponseEntity<List<Map<String, Object>>> getLines(@PathVariable Long id) {
        String userId = userService.getCurrentUserId();
        if (userId == null)
            return ResponseEntity.status(401).build();

        List<Map<String, Object>> lines = ligneInventaireRepository.findByInventaireId(id).stream()
                .map(l -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("id", l.getId());
                    m.put("pieceId", l.getPiece().getId());
                    m.put("pieceNom", l.getPiece().getDesignation());
                    m.put("pieceRef", l.getPiece().getReference());
                    m.put("pieceCode", l.getPiece().getCodeBarre());
                    m.put("pieceImg", l.getPiece().getImageUrl());
                    m.put("statut", l.getStatutLigne());
                    m.put("stockTheorique", l.getStockTheorique());
                    m.put("stockPhysique", l.getStockPhysique());
                    m.put("justification", l.getJustification());
                    m.put("isMine", userId.equals(l.getResponsableLogistiqueId()));

                    if (l.getPiece().getDetails() != null) {
                        List<Map<String, String>> details = l.getPiece().getDetails().stream()
                                .map(d -> {
                                    Map<String, String> dm = new HashMap<>();
                                    dm.put("nom", d.getParametre() != null ? d.getParametre().getNom() : "");
                                    dm.put("valeur", d.getValeur() != null ? d.getValeur() : "");
                                    return dm;
                                })
                                .toList();
                        m.put("details", details);
                    } else {
                        m.put("details", List.of());
                    }

                    return m;
                })
                .toList();

        return ResponseEntity.ok(lines);
    }

    @PostMapping("/{id}/scan")
    public ResponseEntity<Map<String, Object>> scanBarcode(@PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        String barcode = (String) body.get("barcode");
        Integer physicalStock = (body.get("physicalStock") != null) ? ((Number) body.get("physicalStock")).intValue()
                : 0;
        Boolean force = (body.get("force") != null) ? (Boolean) body.get("force") : false;
        String justification = (String) body.get("justification");

        Entreprise entreprise = userService.getCurrentUserEntreprise();
        if (entreprise == null) {
            return ResponseEntity.ok(
                    Map.of("success", false, "message", "Utilisateur non rattaché à une entreprise"));
        }

        String userId = userService.getCurrentUserId();
        if (userId == null)
            return ResponseEntity.ok(Map.of("success", false, "message", "Utilisateur non authentifié"));

        Optional<PieceDetachee> pieceOpt = pieceDetacheeRepository.findByCodeBarreAndEntreprise(barcode, entreprise);
        if (pieceOpt.isEmpty()) {
            return ResponseEntity.ok(Map.of("success", false, "message", "Code barre inconnu dans votre entreprise"));
        }

        PieceDetachee piece = pieceOpt.get();

        System.out.println("[SCAN] Piece found: " + piece.getDesignation() + " | archivee=" + piece.getArchivee());

        if (Boolean.TRUE.equals(piece.getArchivee())) {
            return ResponseEntity.ok(
                    Map.of("success", false, "message", "Cette pièce est archivée et ne peut pas être scannée"));
        }

        LigneInventaire ligne = ligneInventaireRepository.findByInventaireIdAndPieceId(id, piece.getId())
                .orElse(null);

        System.out.println(
                "[SCAN] Inventaire #" + id + " | Piece #" + piece.getId() + " | Ligne found=" + (ligne != null));

        if (ligne == null) {
            return ResponseEntity.ok(
                    Map.of("success", false, "message",
                            "Cette pièce ne fait pas partie de cet inventaire (ID=" + id + ")"));
        }

        if (ligne.getStatutLigne() != LigneStatut.A_SCANNER) {
            if (ligne.getResponsableLogistiqueId() != null && !ligne.getResponsableLogistiqueId().equals(userId)) {
                return ResponseEntity.ok(
                        Map.of("success", false, "message",
                                "Cette pièce a déjà été scannée par un autre responsable logistique et est en attente d'audit. Vous ne pouvez pas la modifier."));
            } else if (ligne.getResponsableLogistiqueId() != null
                    && ligne.getResponsableLogistiqueId().equals(userId)) {
                if (!force) {
                    return ResponseEntity.ok(
                            Map.of("success", false,
                                    "requireConfirmation", true,
                                    "oldStock", ligne.getStockPhysique(),
                                    "message",
                                    "Vous avez déjà scanné cette pièce avec la quantité " + ligne.getStockPhysique()
                                            + ". Voulez-vous vraiment l'écraser par " + physicalStock + " ?"));
                }
            }
        }

        ligne.setStockPhysique(physicalStock);
        if (justification != null && !justification.trim().isEmpty()) {
            ligne.setJustification(justification);
        }
        ligne.setDateScan(LocalDateTime.now());
        ligne.setStatutLigne(LigneStatut.EN_ATTENTE_AUDIT);
        ligne.setResponsableLogistiqueId(userId);

        ligneInventaireRepository.save(ligne);

        // 🔔 Notifier les auditeurs qu'une pièce a été scannée
        try {
            String nomPiece = piece.getDesignation();
            String msg = "La pièce '" + nomPiece + "' (Réf: " + piece.getReference()
                    + ") vient d'être scannée avec une quantité de " + physicalStock + ".";
            notificationService.createNotificationForRoles(
                    "SCAN EFFECTUÉ",
                    msg,
                    NotificationType.INFO,
                    java.util.Arrays.asList(Role.AUDITEUR, Role.ADMINISTRATEUR));
        } catch (Exception e) {
            System.err.println("[NOTIF] Erreur lors de l'envoi de la notification de scan: " + e.getMessage());
        }

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("piece", piece.getDesignation());
        res.put("ecart", physicalStock - ligne.getStockTheorique());
        return ResponseEntity.ok(res);
    }

    @PostMapping("/create")
    public ResponseEntity<Map<String, Object>> createInventory() {
        Entreprise entreprise = userService.getCurrentUserEntreprise();
        if (entreprise == null) {
            return ResponseEntity.status(403).build();
        }

        Inventaire inv = new Inventaire();
        inv.setNom("Audit Mobile - " + LocalDateTime.now().getDayOfMonth() + "/" + LocalDateTime.now().getMonthValue());
        inv.setDate(LocalDateTime.now());
        inv.setEntrepriseId(entreprise.getId());
        inv.setEstTermine(false);
        inv.setCreateurId(userService.getCurrentUserId());
        inv.setHeureDebutEffective(LocalDateTime.now());
        inv.setEstValide(false);

        Inventaire saved = inventaireRepository.save(inv);

        List<PieceDetachee> pieces = pieceDetacheeRepository.findActiveByEntreprise(entreprise);
        for (PieceDetachee p : pieces) {
            LigneInventaire l = new LigneInventaire();
            l.setInventaire(saved);
            l.setPiece(p);
            l.setStockTheorique(p.getQuantite() != null ? p.getQuantite() : 0);
            l.setStatutLigne(LigneStatut.A_SCANNER);
            ligneInventaireRepository.save(l);
        }

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("id", saved.getId());
        res.put("nom", saved.getNom());

        // 🔔 Notifier les responsables logistiques qu'un inventaire a démarré
        try {
            notificationService.createNotificationForRoles(
                    "NOUVEL INVENTAIRE",
                    "Un inventaire a été lancé : '" + saved.getNom() + "'. Connectez-vous pour commencer à scanner.",
                    NotificationType.INFO,
                    java.util.Arrays.asList(Role.RESPONSABLE_LOGISTIQUE, Role.ADMINISTRATEUR));
        } catch (Exception e) {
            System.err.println("[NOTIF] Erreur notification création inventaire: " + e.getMessage());
        }

        return ResponseEntity.ok(res);
    }

    @PostMapping("/lignes/{ligneId}/justifier")
    public ResponseEntity<Map<String, Object>> updateJustification(@PathVariable Long ligneId,
            @RequestBody Map<String, String> body) {
        String justification = body.get("justification");
        if (justification == null || justification.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Justification obligatoire"));
        }

        Optional<LigneInventaire> ligneOpt = ligneInventaireRepository.findById(ligneId);
        if (ligneOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        LigneInventaire ligne = ligneOpt.get();
        ligne.setJustification(justification);
        ligneInventaireRepository.save(ligne);

        return ResponseEntity.ok(Map.of("success", true));
    }
}
