import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  String? lastScannedCode;
  DateTime? lastScanTime;

  Future<void> _onDetect(BarcodeCapture capture) async {
    // Check isProcessing first to avoid overlapping scans
    if (isProcessing) return;

    final String? code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    // Éviter de scanner le même code en boucle indéfiniment s'il reste sous la caméra
    if (code == lastScannedCode && lastScanTime != null) {
      if (DateTime.now().difference(lastScanTime!).inSeconds < 3) {
        return; // Ignore ce scan temporellement
      }
    }

    lastScannedCode = code;
    lastScanTime = DateTime.now();

    try {
      setState(() => isProcessing = true);

      // We process the barcode without stopping the camera to avoid
      // UI thread blocking found on some devices (Xiaomi/Impeller issues).
      await _processBarcode(code);
    } catch (e) {
      debugPrint("Scanner error: $e");
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _processBarcode(String barcode) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);

      // Optimization: Fetch piece info and active inventory in parallel
      final results = await Future.wait([
        api.get('/mobile/pieces/info?barcode=$barcode'),
        api.get('/mobile/inventaires/active'),
      ]);

      final pieceResponse = results[0];
      final invRes = results[1];

      if (mounted) {
        if (pieceResponse.statusCode == 200 && pieceResponse.data != null) {
          final piece = pieceResponse.data;

          Map<String, dynamic>? activeLine;
          bool isNotInInventory = false;

          if (invRes.statusCode == 200 && invRes.data != null) {
            try {
              // Now fetch lines only if we have an active inventory
              final linesRes = await api.get(
                '/mobile/inventaires/${invRes.data['id']}/lignes',
              );
              final lines = linesRes.data as List;
              try {
                activeLine = lines.firstWhere((l) => l['pieceCode'] == barcode);
              } catch (_) {
                isNotInInventory = true;
              }
            } catch (_) {}
          }

          // Turn off torch if it was on (compatible with mobile_scanner v6)
          if (controller.torchEnabled) {
            await controller.toggleTorch();
          }

          await _showPieceDetails(piece, barcode, activeLine, isNotInInventory);
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pièce introuvable"),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pièce introuvable"),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
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
    bool isValideOrRefuse = false;

    if (activeLine != null) {
      final status = activeLine['statut'];
      final isMine = activeLine['isMine'] == true;
      if (status == 'VALIDE' || status == 'REFUSE') {
        isValideOrRefuse = true;
      } else if (status != 'A_SCANNER' && !isMine && status != null) {
        isLockedByOther = true;
      }
    }

    // Ensure state is clean before showing modal
    setState(() => isSubmitting = false);
    _quantityController.clear();
    if (isLockedByOther) {
      _quantityController.text = activeLine!['stockPhysique']?.toString() ?? "";
    }

    debugPrint("[SCAN] Showing details for: $scannedBarcode");

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 2),
            ],
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
                      color: const Color(0xFFE2E8F0),
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
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child:
                            (piece['imageUrl'] != null &&
                                (piece['imageUrl'] as String).isNotEmpty)
                            ? Image.network(
                                piece['imageUrl'].toString().startsWith('http')
                                    ? piece['imageUrl']
                                    : "${AppConstants.webBackendUrl}${piece['imageUrl']}",
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/default-piece.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/images/default-piece.png',
                                fit: BoxFit.cover,
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
                              color: Color(0xFF0F172A),
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
                  child: Divider(color: Color(0xFFF1F5F9)),
                ),

                // SPECS GRID
                if (piece['details'] != null &&
                    (piece['details'] as List).isNotEmpty) ...[
                  Text(
                    "CARACTÉRISTIQUES",
                    style: TextStyle(
                      color: const Color(0xFF0F172A).withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['nom']?.toString().toUpperCase() ?? 'DETAIL',
                              style: TextStyle(
                                color: const Color(0xFF0F172A).withOpacity(0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              d['valeur']?.toString() ?? 'N/A',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
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
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "COMPTAGE PHYSIQUE",
                        style: TextStyle(
                          color: const Color(0xFF0F172A).withOpacity(0.3),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (isArchived)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.archive_outlined,
                                color: Color(0xFFEF4444),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Cette pièce est archivée et ne peut plus être auditee.",
                                  style: TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isLockedByOther)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.lock_outline,
                                color: Color(0xFFEF4444),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Cette pièce a déjà été scannée par un autre responsable.",
                                  style: TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isNotInInventory)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFF59E0B),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Pièce hors inventaire. Mettez-la de côté pour l'auditeur.",
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isValideOrRefuse)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Pièce déjà auditée. Réactivation par auditeur nécessaire.",
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          autofocus:
                              !isLockedByOther &&
                              !isNotInInventory &&
                              !isArchived &&
                              !isValideOrRefuse,
                          enabled:
                              !isLockedByOther &&
                              !isNotInInventory &&
                              !isArchived &&
                              !isValideOrRefuse,
                          style: TextStyle(
                            color:
                                (isLockedByOther ||
                                    isNotInInventory ||
                                    isArchived ||
                                    isValideOrRefuse)
                                ? const Color(0xFF94A3B8)
                                : Theme.of(context).primaryColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                          decoration: InputDecoration(
                            hintText: "0",
                            hintStyle: TextStyle(
                              color: const Color(0xFF94A3B8).withOpacity(0.3),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 20,
                            ),
                          ),
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
                            isArchived ||
                            isValideOrRefuse
                        ? null
                        : () {
                            debugPrint("[SCAN] Validate button pressed");
                            final quantityStr = _quantityController.text.trim();
                            debugPrint(
                              "[SCAN] Quantity entered: '$quantityStr'",
                            );

                            final quantityDouble = double.tryParse(quantityStr);
                            if (quantityDouble != null) {
                              final int quantity = quantityDouble.round();
                              debugPrint(
                                "[SCAN] Starting submission for $scannedBarcode with quantity $quantity",
                              );
                              _submitScan(
                                scannedBarcode,
                                quantity,
                                setModalState: setModalState,
                              );
                            } else {
                              debugPrint("[SCAN] Invalid quantity detected");
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
                      disabledBackgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            isArchived
                                ? "PIÈCE ARCHIVÉE"
                                : isValideOrRefuse
                                ? "DÉJÀ AUDITÉE"
                                : isNotInInventory
                                ? "HORS INVENTAIRE"
                                : isLockedByOther
                                ? "DÉJÀ SCANNÉ"
                                : "VALIDER LE SCAN",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              fontSize: 14,
                              color:
                                  (isLockedByOther ||
                                      isNotInInventory ||
                                      isArchived ||
                                      isValideOrRefuse)
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                ),
              ],
            ),
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
    StateSetter? setModalState,
  }) async {
    if (isSubmitting) {
      debugPrint("[SCAN] Already submitting, ignoring...");
      return;
    }

    debugPrint(
      "[SCAN] _submitScan: barcode=$barcode, qty=$quantity, force=$force",
    );

    if (setModalState != null) {
      setModalState(() => isSubmitting = true);
    }
    setState(() => isSubmitting = true);

    try {
      if (!mounted) return;
      final api = Provider.of<ApiService>(context, listen: false);
      debugPrint("[SCAN] Fetching active inventory...");
      final invRes = await api.get('/mobile/inventaires/active');

      if (invRes.statusCode != 200 || invRes.data == null) {
        debugPrint(
          "[SCAN] No active inventory found (status: ${invRes.statusCode})",
        );
        throw "Aucun inventaire actif";
      }

      final invId = invRes.data['id'];
      final fullPath = '/mobile/inventaires/$invId/scan';
      debugPrint("[SCAN] Submitting scan to: ${api.baseUrl}$fullPath");

      final res = await api.post(
        fullPath,
        data: {
          'barcode': barcode,
          'physicalStock': quantity,
          'force': force,
          if (justification != null) 'justification': justification,
        },
      );

      debugPrint("[SCAN] API Response received: ${res.data}");

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
            if (mounted) setState(() => isSubmitting = false);
            if (setModalState != null && mounted)
              setModalState(() => isSubmitting = false);

            // On attend un court instant pour laisser le dialogue se fermer proprement
            await Future.delayed(const Duration(milliseconds: 100));

            return _submitScan(
              barcode,
              quantity,
              force: true,
              justification: justifController.text,
              setModalState: setModalState,
            );
          } else {
            if (mounted) setState(() => isSubmitting = false);
            if (setModalState != null && mounted)
              setModalState(() => isSubmitting = false);
            return;
          }
        }
        if (mounted) Navigator.maybePop(context);
        throw res.data['message'] ?? 'Erreur lors du scan';
      }

      if (res.statusCode == 200 && mounted) {
        final ecart = res.data['ecart'] ?? 0;
        final pieceName = res.data['piece'] ?? 'Article';

        if (mounted) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger != null) {
            // Fermer les Snacks précédents pour ne pas s'empiler
            messenger.clearSnackBars();

            if (ecart != 0 && justification == null) {
              // Cas avec écart nécessitant une justification
              // 1) Fermer d'abord la modale de quantité si ouverte
              if (mounted) Navigator.maybePop(context);
              // 2) Attendre que l'animation de fermeture soit terminée avant d'ouvrir la suivante
              await Future.delayed(const Duration(milliseconds: 350));
              if (mounted) await _showJustificationModal(pieceName, barcode, ecart);
            } else {
              // Cas succès parfait ou déjà justifié
              if (mounted) Navigator.maybePop(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          justification != null
                              ? "Scan forcé et justifié avec succès : $pieceName"
                              : "Scan enregistré avec succès : $pieceName",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF0D9488),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // S'assurer que le modal est fermé si l'exception arrive avant
        try {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } catch (_) {}

        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll("Exception:", "").trim()),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
        if (setModalState != null) {
          setModalState(() => isSubmitting = false);
        }
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

                            // Capturer le navigator AVANT l'appel async
                            // (le contexte de la bottom-sheet peut devenir invalide après la fermeture)
                            final navigator = Navigator.of(context);

                            await api.post(
                              '/mobile/inventaires/lignes/${line['id']}/justifier',
                              data: {'justification': reasonController.text},
                            );

                            // Fermer la modale de justification via le navigator capturé
                            if (mounted && navigator.canPop()) {
                              navigator.pop();
                            }

                            // Attendre que la fermeture soit animée
                            await Future.delayed(const Duration(milliseconds: 200));

                            // Afficher le message de succès via le contexte stable de l'écran
                            if (mounted) {
                              ScaffoldMessenger.maybeOf(this.context)
                                ?..clearSnackBars()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.check_circle,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Scan enregistré avec succès !',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF0D9488),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 3),
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
        ],
      ),
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(controller: controller, onDetect: _onDetect),

          // 2. Focused Overlay (Subtle)
          Container(color: Colors.black.withOpacity(0.2)),

          // 3. Scanner Square (Vu-finder)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  if (isProcessing)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),

          // 4. "Saisie Manuelle" Button
          Positioned(
            bottom: 100, // Positioned below the center frame
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.keyboard_outlined, size: 18),
                label: const Text(
                  "SAISIE MANUELLE",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 5,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),

          // 5. Instruction Text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  "Placez le code à barres dans le cadre",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.keyboard_outlined,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Saisie Manuelle",
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
            const Text(
              "Entrez le code à barres manuellement pour identifier la pièce.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Code à barres...",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D9488),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ANNULER",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final code = textController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _processBarcode(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "VALIDER",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    _quantityController.dispose();
    controller.dispose();
    super.dispose();
  }
}
