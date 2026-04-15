import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/inventory_provider.dart';
import '../../core/constants/app_constants.dart';

class InventoryListTab extends StatefulWidget {
  const InventoryListTab({super.key});

  @override
  State<InventoryListTab> createState() => _InventoryListTabState();
}

class _InventoryListTabState extends State<InventoryListTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      provider.addListener(_onProviderChange);
      provider.fetchLines();
    });
  }

  @override
  void dispose() {
    Provider.of<InventoryProvider>(
      context,
      listen: false,
    ).removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    if (provider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      provider.clearError();
    }
  }

  Future<void> _fetchLines() async {
    await Provider.of<InventoryProvider>(context, listen: false).fetchLines();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0D9488);
    const textColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pièces en inventaire",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Consumer<InventoryProvider>(
              builder: (context, provider, _) => Text(
                provider.activeInventoryName ?? "Aucune mission active",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: _fetchLines,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
            );
          }
          if (provider.lines.isEmpty || !provider.hasActiveInventory) {
            return _buildEmptyState(primaryColor, textColor);
          }
          return RefreshIndicator(
            onRefresh: _fetchLines,
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: provider.lines.length,
              itemBuilder: (context, index) {
                return _buildPremiumItemCard(
                  provider.lines[index],
                  primaryColor,
                  textColor,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumItemCard(
    Map<String, dynamic> line,
    Color primaryColor,
    Color textColor,
  ) {
    final String status = line['statut'] ?? 'A_SCANNER';
    final bool isMine = line['isMine'] ?? false;
    final List<dynamic> details = line['details'] ?? [];

    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'VALIDE':
        statusColor = const Color(0xFF10B981);
        statusLabel = "Validé";
        break;
      case 'EN_ATTENTE_AUDIT':
        statusColor = const Color(0xFF6366F1); // Indigo color for pending
        statusLabel = "En attente";
        break;
      case 'A_RECOMPTER':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = "Ré-audit";
        break;
      case 'REFUSE':
        statusColor = const Color(0xFFEF4444);
        statusLabel = "Refusé";
        break;
      default:
        statusColor = primaryColor;
        statusLabel = "À scanner";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMine ? primaryColor.withOpacity(0.2) : Colors.grey.shade100,
          width: isMine ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  (line['pieceImg'] != null &&
                      (line['pieceImg'] as String).isNotEmpty)
                  ? Image.network(
                      line['pieceImg'].startsWith('http')
                          ? line['pieceImg']
                          : "${AppConstants.webBackendUrl}${line['pieceImg']}",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey.shade300,
                        size: 24,
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey.shade300,
                      size: 24,
                    ),
            ),
          ),
          title: Text(
            line['pieceNom'] ?? 'Article sans nom',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontSize: 15,
              letterSpacing: -0.3,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line['pieceRef'] ?? 'Pas de référence',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
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
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "VOTRE SCAN",
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    line['stockPhysique'] == null
                        ? "?"
                        : "${line['stockPhysique']}",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CARACTÉRISTIQUES",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (details.isEmpty)
                    const Text(
                      "Aucun détail supplémentaire disponible",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: details.map((d) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            "${d['nom']}: ${d['valeur']}",
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: primaryColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Aucune pièce à scanner",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "L'inventaire est peut-être terminé ou vide.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
