import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/app_constants.dart';

class InventoryListTab extends StatefulWidget {
  const InventoryListTab({super.key});

  @override
  State<InventoryListTab> createState() => _InventoryListTabState();
}

class _InventoryListTabState extends State<InventoryListTab> {
  List<dynamic> lines = [];
  bool isLoading = true;
  bool hasActiveInventory = false;
  String? activeInventoryName;

  @override
  void initState() {
    super.initState();
    _fetchLines();
  }

  Future<void> _fetchLines() async {
    setState(() => isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);

      final invRes = await api.get('/mobile/inventaires/active');
      if (invRes.statusCode == 200 && invRes.data != null) {
        final invId = invRes.data['id'];
        activeInventoryName = invRes.data['nom'];

        final linesRes = await api.get('/mobile/inventaires/$invId/lignes');
        if (linesRes.statusCode == 200) {
          setState(() {
            lines = linesRes.data;
            hasActiveInventory = true;
          });
        }
      } else {
        setState(() {
          lines = [];
          hasActiveInventory = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching inventory lines: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const slate900 = Color(0xFF0F172A);
    const primaryColor = Color(0xFF0D9488);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inventaire Collaboratif",
              style: TextStyle(
                color: slate900,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (activeInventoryName != null)
              Text(
                activeInventoryName!,
                style: TextStyle(
                  fontSize: 12,
                  color: slate900.withOpacity(0.5),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: slate900.withOpacity(0.5)),
            onPressed: _fetchLines,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: slate900.withOpacity(0.05)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : lines.isEmpty
          ? _buildEmptyState(primaryColor, slate900)
          : RefreshIndicator(
              onRefresh: _fetchLines,
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                itemCount: lines.length,
                itemBuilder: (context, index) {
                  return _buildLineItem(lines[index], primaryColor, slate900);
                },
              ),
            ),
    );
  }

  Widget _buildLineItem(
    Map<String, dynamic> line,
    Color primaryColor,
    Color slate900,
  ) {
    final String status = line['statut'] ?? 'A_SCANNER';
    final bool isMine = line['isMine'] ?? false;
    final List<dynamic> details = line['details'] ?? [];

    Color statusColor = status == 'VALIDE'
        ? const Color(0xFF10B981)
        : (status == 'REFUSE' || status == 'A_RECOMPTER'
              ? const Color(0xFFF59E0B)
              : const Color(0xFF0D9488));
    String statusLabel = status == 'VALIDE'
        ? "Validé"
        : (status == 'REFUSE'
              ? "Rejeté"
              : (status == 'A_RECOMPTER' ? "À re-compter" : "À scanner"));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMine
              ? const Color(0xFF0D9488).withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: slate900.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (line['pieceImg'] != null && (line['pieceImg'] as String).isNotEmpty)
                ? Image.network(
                    line['pieceImg'].startsWith('http')
                        ? line['pieceImg']
                        : "${AppConstants.webBackendUrl}${line['pieceImg']}",
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
        title: Text(
          line['pieceNom'] ?? 'Sans Nom',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: slate900,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Ref: ${line['pieceRef'] ?? 'N/A'}",
              style: TextStyle(fontSize: 12, color: slate900.withOpacity(0.4)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "MIEN",
                      style: TextStyle(
                        fontSize: 10,
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  status == 'A_SCANNER'
                      ? "Qté: ?"
                      : "Qté: ${line['stockPhysique']}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: slate900,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          if (details.isEmpty)
            const Text(
              "Aucun détail",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: details.map((d) {
                final bool isBarcode = (d['nom'] as String)
                    .toLowerCase()
                    .contains('code');
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isBarcode
                        ? primaryColor.withOpacity(0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isBarcode
                          ? primaryColor.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    "${d['nom']}: ${d['valeur']}",
                    style: TextStyle(
                      fontSize: 11,
                      color: isBarcode
                          ? primaryColor
                          : slate900.withOpacity(0.6),
                      fontWeight: isBarcode
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, Color slate900) {
    if (hasActiveInventory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: slate900.withOpacity(0.05),
            ),
            const SizedBox(height: 16),
            const Text(
              "Aucune pièce à scanner",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 100,
              color: slate900.withOpacity(0.05),
            ),
            const SizedBox(height: 24),
            Text(
              "Aucun Inventaire Actif",
              style: TextStyle(
                color: slate900,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "En attente d'un inventaire planifié par l'administration.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: slate900.withOpacity(0.4),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
