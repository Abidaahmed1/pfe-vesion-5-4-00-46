package com.gestionStock_backend_mobile.controller;

import com.gestionStock_backend_mobile.entity.Stock.Inventaire;
import com.gestionStock_backend_mobile.entity.Stock.LigneInventaire;
import com.gestionStock_backend_mobile.entity.Stock.LigneInventaireHistorique;
import com.gestionStock_backend_mobile.entity.Stock.LigneStatut;
import com.gestionStock_backend_mobile.repository.Stock.InventaireRepository;
import com.gestionStock_backend_mobile.repository.Stock.LigneInventaireHistoriqueRepository;
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
    private final LigneInventaireHistoriqueRepository ligneInventaireHistoriqueRepository;
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
    /*
     * @GetMapping("/{id}/stats")
     * public ResponseEntity<Map<String, Object>> getStats(@PathVariable Long id) {
     * String userId = userService.getCurrentUserId();
     * if (userId == null)
     * return ResponseEntity.status(401).build();
     * 
     * long total = ligneInventaireRepository.countByInventaireId(id);
     * long aScanner =
     * ligneInventaireRepository.countByInventaireIdAndStatutLigne(id,
     * LigneStatut.A_SCANNER);
     * long scanned = total - aScanner;
     * 
     * long discrepanciesCount =
     * ligneInventaireRepository.findByInventaireId(id).stream()
     * .filter(l -> l.getEcart() != null && l.getEcart() != 0)
     * .count();
     * 
     * List<Map<String, String>> piecesARecompter =
     * ligneInventaireRepository.findByInventaireId(id).stream()
     * .filter(l -> l.getStatutLigne() == LigneStatut.A_RECOMPTER)
     * .map(l -> {
     * Map<String, String> m = new HashMap<>();
     * m.put("pieceNom", l.getPiece() != null ? l.getPiece().getDesignation() :
     * "Inconnu");
     * String respId = l.getResponsableLogistiqueId();
     * m.put("responsableId", respId != null ? respId : "inconnu");
     * String respNom = "Inconnu";
     * if (respId != null) {
     * respNom = userService.getUserById(respId)
     * .map(u -> (u.getFirstName() != null ? u.getFirstName() + " " +
     * u.getLastName()
     * : "Responsable"))
     * .orElse("Responsable Inconnu");
     * }
     * m.put("responsableNom", respNom);
     * m.put("message", "À recompter");
     * return m;
     * }).toList();
     * 
     * Map<String, Object> stats = new HashMap<>();
     * stats.put("totalPieces", total);
     * stats.put("scannedPieces", scanned);
     * stats.put("progress", total == 0 ? 0 : (double) scanned / total);
     * stats.put("lastScan", LocalDateTime.now());
     * stats.put("piecesARecompter", piecesARecompter);
     * stats.put("aRecompterCount", piecesARecompter.size());
     * stats.put("discrepanciesCount", discrepanciesCount);
     * 
     * return ResponseEntity.ok(stats);
     * }
     */

    @GetMapping("/{id}/lignes")
    public ResponseEntity<List<Map<String, Object>>> getLines(@PathVariable Long id) {
        String userId = userService.getCurrentUserId();
        if (userId == null)
            return ResponseEntity.status(401).build();

        List<Map<String, Object>> lines = ligneInventaireRepository.findByInventaireId(id).stream()
                .map(l -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("id", l.getId());
                    m.put("pieceId", l.getPiece() != null ? l.getPiece().getId() : null);
                    String designation = l.getPiece() != null ? l.getPiece().getDesignation() : "Inconnu";
                    m.put("pieceNom", designation);
                    m.put("pieceRef", l.getPiece() != null ? l.getPiece().getReference() : "N/A");
                    m.put("pieceCode", l.getPiece() != null ? l.getPiece().getCodeBarre() : "N/A");
                    String img = l.getPiece() != null ? l.getPiece().getImageUrl() : null;
                    m.put("pieceImg", img);

                    System.out.println("[DEBUG] Line " + l.getId() + ": Piece=" + designation + ", Img=" + img);
                    m.put("statut", l.getStatutLigne());
                    m.put("stockTheorique", l.getStockTheorique());
                    m.put("stockPhysique", l.getStockPhysique());
                    m.put("justification", l.getJustification());
                    m.put("isMine", userId.equals(l.getResponsableLogistiqueId()));

                    if (l.getPiece() != null && l.getPiece().getDetails() != null) {
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
            @RequestBody Map<String, Object> request) {
        System.out.println("[SCAN] ===> START: id=" + id + ", request=" + request);

        try {
            String barcode = (String) request.get("barcode");

            // 1. Parsing Quantité
            Integer physicalStock = 0;
            try {
                Object psObj = request.get("physicalStock");
                if (psObj != null) {
                    if (psObj instanceof Number)
                        physicalStock = ((Number) psObj).intValue();
                    else
                        physicalStock = Integer.parseInt(psObj.toString());
                }
            } catch (Exception ex) {
                System.err.println("[SCAN] Qty parse error: " + ex.getMessage());
            }

            Boolean force = Boolean.TRUE.equals(request.get("force"));
            String justification = (String) request.get("justification");

            // 2. Identification Utilisateur & Entreprise
            System.out.println("[SCAN] Identifying user...");
            String userId = userService.getCurrentUserId();
            Entreprise entreprise = userService.getCurrentUserEntreprise();

            // Fallback pour les tests si sécurité bypassée
            if (userId == null) {
                System.out.println("[SCAN] WARNING: userId is null, using 'MOBILE_APP'");
                userId = "MOBILE_APP";
            }

            // 3. Recherche de la pièce
            System.out.println("[SCAN] Searching piece: " + barcode);
            PieceDetachee piece = null;
            if (entreprise != null) {
                piece = pieceDetacheeRepository.findByCodeBarreAndEntreprise(barcode, entreprise).orElse(null);
            }

            if (piece == null) {
                System.out.println("[SCAN] Piece not found: " + barcode);
                return ResponseEntity.ok(Map.of("success", false, "message", "Code barre inconnu (" + barcode + ")"));
            }

            // 4. Recherche de la ligne d'inventaire
            System.out.println("[SCAN] Linking with inventory " + id + " for piece " + piece.getId());
            LigneInventaire ligne = ligneInventaireRepository.findByInventaireIdAndPieceId(id, piece.getId())
                    .orElse(null);

            if (ligne == null) {
                System.out.println("[SCAN] Ligne not found in inventory " + id);
                return ResponseEntity.ok(Map.of("success", false, "message", "Pièce non listée dans cet inventaire."));
            }

            // 5. Checks de Statut
            if (ligne.getInventaire() != null && ligne.getInventaire().isEstValide()) {
                return ResponseEntity
                        .ok(Map.of("success", false, "message", "L'inventaire complet a été validé par l'auditeur."));
            }

            LigneStatut currentStatus = ligne.getStatutLigne();
            System.out.println("[SCAN] Current status: " + currentStatus);

            // 5. Checks de Statut
            // On bloque SEULEMENT si l'inventaire GLOBAL est validé
            if (ligne.getInventaire() != null && ligne.getInventaire().isEstValide()) {
                return ResponseEntity
                        .ok(Map.of("success", false, "message", "L'inventaire complet a été validé par l'auditeur."));
            }

            // Si c'est "À RECOMPTER", on autorise TOUJOURS le scan
            if (currentStatus != LigneStatut.A_RECOMPTER) {
                // Pour les autres statuts, on bloque UNIQUEMENT si l'auditeur a déjà finalisé
                // sa décision (VALIDE ou REFUSE)
                boolean isDecisionFinal = (currentStatus == LigneStatut.VALIDE || currentStatus == LigneStatut.REFUSE);

                if (isDecisionFinal) {
                    return ResponseEntity.ok(Map.of("success", false, "message", "Déjà validé par l'auditeur."));
                }
            }

            if (currentStatus == LigneStatut.EN_ATTENTE_AUDIT && !force) {
                Integer previousQty = ligne.getStockPhysique() != null ? ligne.getStockPhysique() : 0;
                String msg = "Vous avez déjà saisi un stock de " + previousQty
                        + " pour cet article. Voulez-vous modifier cette quantité ?";
                return ResponseEntity.ok(Map.of("success", false, "requireConfirmation", true, "message", msg));
            }

            // 6. Sauvegarde
            LigneStatut oldStatus = currentStatus;
            Integer oldQty = ligne.getStockPhysique();

            System.out.println(
                    "[SCAN] Updating line " + ligne.getId() + " - OldQty: " + oldQty + ", NewQty: " + physicalStock);

            ligne.setStockPhysique(physicalStock);
            ligne.setEcart(physicalStock - (ligne.getStockTheorique() != null ? ligne.getStockTheorique() : 0));
            ligne.setJustification(justification);
            ligne.setDateScan(LocalDateTime.now());
            ligne.setStatutLigne(LigneStatut.EN_ATTENTE_AUDIT);
            ligne.setResponsableLogistiqueId(userId);

            ligneInventaireRepository.save(ligne);
            // 6.5 Record History (Wrapped in try-catch to never block the main flow)
            try {
                String actionName = (oldQty == null) ? "SCAN_MOBILE" : "MISE_A_JOUR_SCAN";

                // Si on était en recomptage, on utilise une action spécifique
                if (oldStatus == LigneStatut.A_RECOMPTER) {
                    actionName = "RECOMPTAGE_MOBILE";
                }

                String detailMsg = (oldStatus == LigneStatut.A_RECOMPTER)
                        ? "Recomptage effectué suite à demande auditeur"
                        : (oldQty == null ? "Scan initial par mobile" : "Mise à jour de la quantité scannée");
                if (justification != null && !justification.isBlank()) {
                    detailMsg += " (Justification: " + justification + ")";
                }

                System.out.println("[SCAN] Recording history...");
                addHistoryToLigne(ligne, actionName, detailMsg, oldQty, physicalStock, oldStatus,
                        LigneStatut.EN_ATTENTE_AUDIT);
                System.out.println("[SCAN] History recorded.");
            } catch (Exception e) {
                System.err.println("[SCAN] History error (non-blocking): " + e.getMessage());
            }

            System.out.println("[SCAN] SUCCESS for barcode: " + barcode);

            // 7. Notification (Async catch)
            try {
                notificationService.createNotificationForRoles("SCAN", piece.getDesignation() + " scanné",
                        NotificationType.INFO, java.util.Arrays.asList(Role.AUDITEUR));
            } catch (Exception e) {
                System.out.println("[SCAN] Notify fail: " + e.getMessage());
            }

            Map<String, Object> responseData = new HashMap<>();
            responseData.put("success", true);
            responseData.put("message", "Scan enregistré");
            responseData.put("piece", piece.getDesignation());
            responseData.put("ecart", ligne.getEcart());
            return ResponseEntity.ok(responseData);

        } catch (Exception e) {
            System.err.println("[SCAN] UNEXPECTED CRASH:");
            e.printStackTrace();
            String msg = (e.getMessage() != null) ? e.getMessage() : e.getClass().getSimpleName();
            return ResponseEntity.status(500).body(Map.of("success", false, "message", "Erreur fatale: " + msg));
        }
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
        String oldJustification = ligne.getJustification();
        ligne.setJustification(justification);
        ligneInventaireRepository.save(ligne);

        addHistoryToLigne(ligne, "MISE_A_JOUR_SCAN",
                "Mise à jour de la justification (Ancienne: " + (oldJustification != null ? oldJustification : "aucune")
                        + ")",
                ligne.getStockPhysique(), ligne.getStockPhysique(),
                ligne.getStatutLigne(), ligne.getStatutLigne());

        return ResponseEntity.ok(Map.of("success", true));
    }

    private void addHistoryToLigne(LigneInventaire ligne, String action, String details,
            Integer oldVal, Integer newVal,
            LigneStatut oldStat, LigneStatut newStat) {
        try {
            com.gestionStock_backend_mobile.entity.user.User currentUser = userService.getCurrentUser().orElse(null);
            LigneInventaireHistorique h = LigneInventaireHistorique.builder()
                    .ligneInventaire(ligne)
                    .action(action)
                    .details(details)
                    .ancienneValeur(oldVal)
                    .nouvelleValeur(newVal)
                    .ancienStatut(oldStat)
                    .nouveauStatut(newStat)
                    .date(LocalDateTime.now())
                    .utilisateur(currentUser)
                    .build();
            ligneInventaireHistoriqueRepository.save(h);
        } catch (Exception e) {
            System.err.println("[HISTORY] Error recording scan history: " + e.getMessage());
        }
    }
}
