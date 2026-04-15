import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/inventory_provider.dart';

class InventoryStatsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialActiveInventory;
  final Map<String, dynamic>? initialStats;

  const InventoryStatsScreen({
    super.key,
    this.initialActiveInventory,
    this.initialStats,
  });

  @override
  State<InventoryStatsScreen> createState() => _InventoryStatsScreenState();
}

class _InventoryStatsScreenState extends State<InventoryStatsScreen> {
  Map<String, dynamic>? activeInventory;
  Map<String, dynamic>? stats;
  bool isLoading = false;

  final Color primaryColor = const Color(0xFF0D9488);
  final Color slate900 = const Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    activeInventory = widget.initialActiveInventory;
    stats = widget.initialStats;
    if (activeInventory == null || stats == null) {
      _fetchData();
    } else {
      // Fetch fresh data in background without showing loading spinner
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDataBackground());
    }
  }

  Future<void> _fetchDataBackground() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final invRes = await api.get('/mobile/inventaires/active');
      if (invRes.statusCode == 200 && invRes.data != null) {
        final inv = invRes.data;
        final statsRes = await api.get('/mobile/inventaires/${inv['id']}/stats');
        if (statsRes.statusCode == 200 && mounted) {
          setState(() {
            activeInventory = inv;
            stats = statsRes.data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching inventory stats: $e');
    }
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);

      final invRes = await api.get('/mobile/inventaires/active');
      if (invRes.statusCode == 200 && invRes.data != null) {
        activeInventory = invRes.data;

        final statsRes = await api.get(
          '/mobile/inventaires/${activeInventory!['id']}/stats',
        );
        if (statsRes.statusCode == 200) {
          stats = statsRes.data;
        }
      }
    } catch (e) {
      debugPrint('Error fetching inventory stats: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Statistiques d'Inventaire",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        shadowColor: Colors.black.withOpacity(0.05),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : activeInventory == null
          ? _buildNoInventory()
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: _fetchData,
              child: _buildStatsView(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchData,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        label: const Text("Actualiser", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildNoInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: primaryColor.withOpacity(0.1),
               shape: BoxShape.circle,
             ),
             child: Icon(Icons.inventory_2_rounded, size: 60, color: primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            "Aucun inventaire actif",
            style: TextStyle(fontSize: 20, color: slate900, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Veuillez en créer un depuis la plateforme web",
            style: TextStyle(color: slate900.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsView() {
    final progress = (stats?['progress'] ?? 0.0) as double;
    final total = stats?['totalPieces'] ?? 0;
    final discrepancies = stats?['discrepanciesCount'] ?? 0;

    return Consumer<InventoryProvider>(
      builder: (context, invProv, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInventoryHeader(),
              const SizedBox(height: 32),
              _buildProgressCard(progress, invProv.countValid + invProv.countPendingAudit, total),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Capacité",
                      "$total",
                      Icons.layers_rounded,
                      primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Écarts",
                      "$discrepancies",
                      Icons.warning_amber_rounded,
                      const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "RÉPARTITION DU SCAN",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: slate900.withOpacity(0.4),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: slate900.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDistributionItem(
                      "Validés",
                      invProv.countValid,
                      const Color(0xFF10B981),
                      total,
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDistributionItem(
                      "En attente",
                      invProv.countPendingAudit,
                      const Color(0xFF6366F1),
                      total,
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDistributionItem(
                      "À scanner",
                      invProv.countToScan,
                      const Color(0xFF94A3B8),
                      total,
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDistributionItem(
                      "Ré-audit",
                      invProv.countReaudit,
                      const Color(0xFFF59E0B),
                      total,
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDistributionItem(
                      "Refusés",
                      invProv.countRefused,
                      const Color(0xFFEF4444),
                      total,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
           decoration: BoxDecoration(
             color: primaryColor.withOpacity(0.1),
             borderRadius: BorderRadius.circular(12),
           ),
           child: Text(
             "EN COURS", 
             style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)
           ),
        ),
        const SizedBox(height: 12),
        Text(
          activeInventory!['nom'] ?? 'Session sans nom',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: slate900),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: slate900.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              "Lancé le ${activeInventory!['date']?.toString().substring(0, 10)}",
              style: TextStyle(color: slate900.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(double progress, int scanned, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: slate900.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progression Globale",
                style: TextStyle(color: slate900, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
               Container(
                 height: 12,
                 decoration: BoxDecoration(
                   color: const Color(0xFFF1F5F9),
                   borderRadius: BorderRadius.circular(10),
                 ),
               ),
               FractionallySizedBox(
                 widthFactor: progress.clamp(0.0, 1.0),
                 child: Container(
                   height: 12,
                   decoration: BoxDecoration(
                     color: primaryColor,
                     borderRadius: BorderRadius.circular(10),
                   ),
                 ),
               ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$scanned sur $total pièces scannées",
            style: TextStyle(color: slate900.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: slate900.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: slate900),
          ),
          Text(
             title, 
             style: TextStyle(color: slate900.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }



  Widget _buildDistributionItem(String label, int value, Color color, int total) {
    final percent = total == 0 ? 0.0 : value / total;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(label.contains("ttente") ? Icons.hourglass_empty_rounded : Icons.check_circle_outline_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: slate900, fontSize: 14)),
                const SizedBox(height: 6),
                Stack(
                  children: [
                     Container(
                       height: 6,
                       decoration: BoxDecoration(
                         color: const Color(0xFFF1F5F9),
                         borderRadius: BorderRadius.circular(4),
                       ),
                     ),
                     FractionallySizedBox(
                       widthFactor: percent.clamp(0.0, 1.0),
                       child: Container(
                         height: 6,
                         decoration: BoxDecoration(
                           color: color,
                           borderRadius: BorderRadius.circular(4),
                         ),
                       ),
                     ),
                  ],
                ),
             ],
           )
        ),
        const SizedBox(width: 16),
        Text("$value", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: slate900)),
      ],
    );
  }
}
