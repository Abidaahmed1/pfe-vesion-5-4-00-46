import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String? inventoryId;

  const BarcodeScannerScreen({super.key, this.inventoryId});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => isProcessing = true);
        controller.stop();
        await _processBarcode(code);
        if (mounted) {
          setState(() => isProcessing = false);
          controller.start();
        }
      }
    }
  }

  Future<void> _processBarcode(String barcode) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);

      // Fetch specific piece details
      final response = await api.get('/mobile/pieces/info?barcode=$barcode');

      if (mounted) {
        if (response.statusCode == 200 && response.data != null) {
          final piece = response.data;

          Map<String, dynamic>? activeLine;
          bool isNotInInventory = false;
          try {
            final invRes = await api.get('/mobile/inventaires/active');
            if (invRes.statusCode == 200) {
              final linesRes = await api.get(
                '/mobile/inventaires/${invRes.data['id']}/lignes',
              );
              final lines = linesRes.data as List;
              try {
                activeLine = lines.firstWhere((l) => l['pieceCode'] == barcode);
              } catch (_) {
                isNotInInventory = true;
              }
            }
          } catch (_) {}

          await _showPieceDetails(piece, barcode, activeLine, isNotInInventory);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Pièce non trouvée: $barcode"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de recherche: $barcode"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _showPieceDetails(
    dynamic piece,
    String scannedBarcode,
    Map<String, dynamic>? activeLine, [
    bool isNotInInventory = false,
  ]) async {
    bool isLockedByOther = false;
    bool isArchived = piece['archivee'] == true;

    if (activeLine != null) {
      final status = activeLine['statut'];
      final isMine = activeLine['isMine'] == true;
      if (status != 'A_SCANNER' && !isMine && status != null) {
        isLockedByOther = true;
      }
    }

    _quantityController.clear();
    if (isLockedByOther) {
      _quantityController.text = activeLine!['stockPhysique']?.toString() ?? "";
    }

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.03),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          piece['imageUrl'] != null &&
                              (piece['imageUrl'] as String).isNotEmpty
                          ? Image.network(
                              piece['imageUrl'].toString().startsWith('http')
                                  ? piece['imageUrl']
                                  : "${AppConstants.webBackendUrl}${piece['imageUrl']}",
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.inventory_2,
                              color: Colors.white10,
                              size: 40,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          piece['nom'] ?? piece['designation'] ?? 'Article',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Réf: ${piece['reference'] ?? 'N/A'}",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusBadge(
                          (piece['archivee'] == true)
                              ? 'Archivé'
                              : (piece['status'] ?? 'Actif'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Colors.white10),
              ),

              // SPECS GRID
              if (piece['details'] != null &&
                  (piece['details'] as List).isNotEmpty) ...[
                const Text(
                  "CARACTÉRISTIQUES",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: (piece['details'] as List).length,
                  itemBuilder: (context, index) {
                    final d = piece['details'][index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['nom']?.toString().toUpperCase() ?? 'DETAIL',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            d['valeur']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // INPUT AREA
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Text(
                      "COMPTAGE PHYSIQUE",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isArchived)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.archive_outlined,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Cette pièce est archivée dans le système et ne peut plus être auditee.",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isLockedByOther)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.lock_outline,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Cette pièce a déjà été scannée par un autre responsable. Modification interdite.",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isNotInInventory)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Cette pièce ne fait pas partie de la liste d'audit. Veuillez la mettre à l'auditeur.",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus:
                          !isLockedByOther && !isNotInInventory && !isArchived,
                      enabled:
                          !isLockedByOther && !isNotInInventory && !isArchived,
                      style: TextStyle(
                        color:
                            (isLockedByOther || isNotInInventory || isArchived)
                            ? Colors.white30
                            : Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: "Quantité Physique",
                        hintStyle: TextStyle(
                          color: Colors.white10,
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed:
                      isSubmitting ||
                          isLockedByOther ||
                          isNotInInventory ||
                          isArchived
                      ? null
                      : () {
                          final quantity = int.tryParse(
                            _quantityController.text,
                          );
                          if (quantity != null) {
                            _submitScan(scannedBarcode, quantity);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Entrez une quantité valide"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    disabledBackgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isArchived
                              ? "PIÈCE ARCHIVÉE"
                              : isNotInInventory
                              ? "HORS INVENTAIRE"
                              : isLockedByOther
                              ? "DÉJÀ SCANNÉ"
                              : "VALIDER LE SCAN",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                (isLockedByOther ||
                                    isNotInInventory ||
                                    isArchived)
                                ? Colors.white54
                                : Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isSubmitting = false;

  Future<void> _submitScan(
    String barcode,
    int quantity, {
    bool force = false,
    String? justification,
  }) async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final invRes = await api.get('/mobile/inventaires/active');
      if (invRes.statusCode != 200 || invRes.data == null)
        throw "Aucun inventaire actif";

      final invId = invRes.data['id'];
      final res = await api.post(
        '/mobile/inventaires/$invId/scan',
        data: {
          'barcode': barcode,
          'physicalStock': quantity,
          'force': force,
          if (justification != null) 'justification': justification,
        },
      );

      if (res.data['success'] == false) {
        if (res.data['requireConfirmation'] == true) {
          if (!mounted) return;
          final TextEditingController justifController =
              TextEditingController();

          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => StatefulBuilder(
              builder: (ctx, setDialogState) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Action requise",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.data['message'] ?? "",
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: justifController,
                      onChanged: (val) => setDialogState(() {}),
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: "Justification obligatoire...",
                        hintStyle: TextStyle(
                          color: const Color(0xFF0F172A).withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              [
                                {'l': "Casse", 'i': Icons.handyman_rounded},
                                {'l': "Perte", 'i': Icons.search_off_rounded},
                                {
                                  'l': "Erreur Saisie",
                                  'i': Icons.edit_note_rounded,
                                },
                                {'l': "Précédent", 'i': Icons.history_rounded},
                              ].map((m) {
                                final label = m['l'] as String;
                                final isSelected =
                                    justifController.text == label;
                                return InkWell(
                                  onTap: () => setDialogState(
                                    () => justifController.text = label,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0D9488)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0D9488)
                                            : Colors.black.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          m['i'] as IconData,
                                          size: 12,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                            fontSize: 10,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        if (justifController.text.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFF87171),
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Veuillez saisir ou choisir un motif",
                                  style: TextStyle(
                                    color: Color(0xFFF87171),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      "Annuler",
                      style: TextStyle(
                        color: const Color(0xFF0F172A).withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      disabledBackgroundColor: Colors.black.withOpacity(0.05),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: justifController.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Oui, écraser",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );

          if (confirm == true) {
            setState(() => isSubmitting = false);
            return _submitScan(
              barcode,
              quantity,
              force: true,
              justification: justifController.text,
            );
          } else {
            setState(() => isSubmitting = false);
            return;
          }
        }
        throw res.data['message'] ?? 'Erreur lors du scan';
      }

      if (res.statusCode == 200 && mounted) {
        final ecart = res.data['ecart'] ?? 0;
        final pieceName = res.data['piece'] ?? 'Article';

        if (ecart != 0 && justification == null) {
          // Only show analysis modal if we didn't just provide a justification in the confirm dialog
          Navigator.pop(context);
          await _showJustificationModal(pieceName, barcode, ecart);
        } else {
          // Either no gap, or gap already justified in the confirmation dialog
          Navigator.pop(context);
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(
                justification != null
                    ? "Scan forcé et justifié : $pieceName"
                    : "Scan validé : $pieceName (Conforme)",
              ),
              backgroundColor: const Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _showJustificationModal(
    String pieceName,
    String barcode,
    int ecart,
  ) async {
    final TextEditingController reasonController = TextEditingController();
    bool isSavingJustif = false;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "ANALYSE DE L'ÉCART",
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Un écart de $ecart unité(s) a été détecté pour $pieceName.",
                style: TextStyle(
                  color: const Color(0xFF0F172A).withOpacity(0.6),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "JUSTIFICATION OBLIGATOIRE",
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: "Expliquez la cause de cet écart...",
                  hintStyle: TextStyle(
                    color: const Color(0xFF0F172A).withOpacity(0.2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      {'l': "Casse", 'i': Icons.handyman_rounded},
                      {'l': "Perte", 'i': Icons.search_off_rounded},
                      {'l': "Erreur Saisie", 'i': Icons.edit_note_rounded},
                      {
                        'l': "Rupture Stock",
                        'i': Icons.remove_shopping_cart_rounded,
                      },
                    ].map((m) {
                      final label = m['l'] as String;
                      final icon = m['i'] as IconData;
                      final isSelected = reasonController.text == label;
                      return InkWell(
                        onTap: () =>
                            setModalState(() => reasonController.text = label),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0D9488)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0D9488)
                                  : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed:
                      (isSavingJustif || reasonController.text.trim().isEmpty)
                      ? null
                      : () async {
                          setModalState(() => isSavingJustif = true);
                          try {
                            final api = Provider.of<ApiService>(
                              context,
                              listen: false,
                            );
                            final invRes = await api.get(
                              '/mobile/inventaires/active',
                            );
                            final linesRes = await api.get(
                              '/mobile/inventaires/${invRes.data['id']}/lignes',
                            );
                            final line = (linesRes.data as List).firstWhere(
                              (l) => l['pieceCode'] == barcode,
                            );

                            await api.post(
                              '/mobile/inventaires/lignes/${line['id']}/justifier',
                              data: {'justification': reasonController.text},
                            );

                            if (mounted) {
                              Navigator.pop(
                                context,
                              ); // Close justification modal
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Analyse enregistrée avec succès !",
                                  ),
                                  backgroundColor: Color(0xFF0D9488),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erreur: $e")),
                            );
                          } finally {
                            setModalState(() => isSavingJustif = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    disabledBackgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isSavingJustif
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "ENREGISTRER L'ANALYSE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Controller and state cleanup
  final TextEditingController _quantityController = TextEditingController();

  Widget _buildStatusBadge(String? status) {
    bool isActive =
        status?.toLowerCase() == 'actif' || status?.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.redAccent).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? Colors.green : Colors.redAccent),
      ),
      child: Text(
        status?.toUpperCase() ?? 'INCONNU',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.redAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanner de Pièces"),
        actions: [
          IconButton(
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () => controller.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: isProcessing
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.keyboard_outlined),
                label: const Text("Saisie Manuelle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Placez le code à barres dans le cadre",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Saisie Manuelle",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Entrez le code à barres",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final code = textController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _processBarcode(code);
              }
            },
            child: const Text("VALIDER"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    controller.dispose();
    super.dispose();
  }
}
