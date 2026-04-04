import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/api_service.dart';

class InventoryStatsScreen extends StatefulWidget {
  const InventoryStatsScreen({super.key});

  @override
  State<InventoryStatsScreen> createState() => _InventoryStatsScreenState();
}

class _InventoryStatsScreenState extends State<InventoryStatsScreen> {
  Map<String, dynamic>? activeInventory;
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
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
      print('Error fetching inventory stats: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistiques d'Inventaire")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeInventory == null
          ? _buildNoInventory()
          : _buildStatsView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchData,
        label: const Text("Actualiser"),
        icon: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildNoInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Aucun inventaire actif en cours",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Veuillez en créer un depuis le Back Web",
            style: TextStyle(color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsView() {
    final progress = (stats?['progress'] ?? 0.0) as double;
    final total = stats?['totalPieces'] ?? 0;
    final scanned = stats?['scannedPieces'] ?? 0;
    final discrepancies = stats?['discrepanciesCount'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInventoryHeader(),
          const SizedBox(height: 24),
          _buildProgressCard(progress, scanned, total),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Total Pièces",
                  "$total",
                  Icons.layers,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  "Écarts",
                  "$discrepancies",
                  Icons.warning_amber,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Répartition du scan",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildScanningDistribution(scanned, total),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Démarrer le scan de pièces"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activeInventory!['nom'] ?? 'Sans Nom',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Lancé le: ${activeInventory!['date']?.toString().substring(0, 10)}",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProgressCard(double progress, int scanned, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Progression Globale",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.white,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$scanned sur $total pièces scannées",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CardTheme.of(context).color ?? Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildScanningDistribution(int scanned, int total) {
    final remaining = total - scanned;
    return Column(
      children: [
        _buildDistributionItem("Pièces Scannées", scanned, Colors.green, total),
        _buildDistributionItem("En attente", remaining, Colors.grey, total),
      ],
    );
  }

  Widget _buildDistributionItem(
    String label,
    int value,
    Color color,
    int total,
  ) {
    final percent = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text("$value", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: percent,
              color: color,
              backgroundColor: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
