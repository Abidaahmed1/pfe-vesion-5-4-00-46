import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/navigation_provider.dart';
import '../../data/providers/notification_provider.dart';
import 'package:mobile_app_gestionstock/data/providers/inventory_provider.dart';
import 'inventory_stats_screen.dart';
import 'notification_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? activeInventory;
  Map<String, dynamic>? stats;
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData(showLoading: true);
    });
  }

  Future<void> _fetchData({bool showLoading = false}) async {
    if (!mounted) return;

    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );

    if (showLoading) setState(() => isLoading = true);
    try {
      // Sync local stats with provider data
      await inventoryProvider.fetchLines(silent: true);

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
      } else {
        activeInventory = null;
        stats = null;
      }
    } catch (e) {
      debugPrint('Dashboard Fetch Error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
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
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "STOCKMASTER",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            Text(
              "Tableau de bord logistique",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [_buildNotificationBell(textColor), const SizedBox(width: 16)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildWelcomeSection(textColor, primaryColor),
                  const SizedBox(height: 32),
                  if (activeInventory != null) ...[
                    _buildActiveMissionCard(primaryColor),
                    const SizedBox(height: 32),
                    _buildPerformanceGrid(textColor, primaryColor),
                    const SizedBox(height: 32),
                    _buildInventoryAnalysis(textColor),
                    const SizedBox(height: 32),
                    _buildUrgencySection(textColor),
                  ] else ...[
                    _buildNoInventoryState(primaryColor, textColor),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeSection(Color textColor, Color primaryColor) {
    final auth = Provider.of<AuthProvider>(context);
    final userName =
        auth.userData?['name'] ??
        auth.userData?['preferred_username'] ??
        'Utilisateur';

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bonjour,",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                userName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "En ligne",
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveMissionCard(Color primaryColor) {
    final progress = (stats?['progress'] ?? 0.0) as double;
    final scanned = stats?['scannedPieces'] ?? 0;
    final total = stats?['totalPieces'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                "INVENTAIRE EN COURS".toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            activeInventory!['nom'] ?? 'Session d\'Audit',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Progression",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.01, 1.0),
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStatItem(
                Icons.qr_code_scanner_rounded,
                "$scanned",
                "Scannés",
              ),
              _buildSimpleStatItem(
                Icons.inventory_2_outlined,
                "$total",
                "Total",
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventoryStatsScreen(
                      initialActiveInventory: activeInventory,
                      initialStats: stats,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceGrid(Color textColor, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "INDICATEURS DE RÉUSSITE",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildKPIContainer(
                "FIABILITÉ",
                "94.2%",
                Icons.verified_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPIContainer(
                "ÉTAT SYNC",
                "OPTIMAL",
                Icons.cloud_done_rounded,
                primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPIContainer(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencySection(Color textColor) {
    final alertsRescan = stats?['piecesARecompter'] as List?;
    if (alertsRescan == null || alertsRescan.isEmpty) return const SizedBox();

    const errorRed = Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "AUDITS À REVOIR",
              style: TextStyle(
                color: errorRed,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: errorRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "${alertsRescan.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...alertsRescan.map((alert) {
          final pieceNom = alert['pieceNom'] ?? 'Article';
          final respNom = alert['responsableNom'] ?? 'Inconnu';
          final sub = Provider.of<AuthProvider>(
            context,
            listen: false,
          ).userData?['sub'];
          final isMe = alert['responsableId'] == sub;
          final displayName = isMe ? "Vous" : respNom;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: errorRed.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: errorRed.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: errorRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: errorRed,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pieceNom,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin_circle_outlined,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Responsable: $displayName",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey,
                  size: 12,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNoInventoryState(Color primaryColor, Color textColor) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucune mission active",
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Les sessions d'audit sont lancées via le portail web.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell(Color textColor) {
    final count = Provider.of<NotificationProvider>(context).unreadCount;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryAnalysis(Color textColor) {
    return Consumer<InventoryProvider>(
      builder: (context, invProv, _) {
        if (invProv.lines.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "RÉPARTITION QUALITATIVE",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(180, 180),
                          painter: InventoryDonutPainter(
                            valid: invProv.percentValid,
                            toScan: invProv.percentToScan,
                            pendingAudit: invProv.percentPendingAudit,
                            refused: invProv.percentRefused,
                            reaudit: invProv.percentReaudit,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${(invProv.percentValid * 100).toInt()}%",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "Validé",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildAnalysisLegend(
                        "Validés",
                        invProv.countValid,
                        const Color(0xFF10B981),
                      ),
                      _buildAnalysisLegend(
                        "En attente",
                        invProv.countPendingAudit,
                        const Color(0xFF6366F1),
                      ),
                      _buildAnalysisLegend(
                        "À scanner",
                        invProv.countToScan,
                        const Color(0xFF94A3B8),
                      ),
                      _buildAnalysisLegend(
                        "Ré-audit",
                        invProv.countReaudit,
                        const Color(0xFFF59E0B),
                      ),
                      _buildAnalysisLegend(
                        "Refusés",
                        invProv.countRefused,
                        const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalysisLegend(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              "$count",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class InventoryDonutPainter extends CustomPainter {
  final double valid;
  final double toScan;
  final double pendingAudit;
  final double refused;
  final double reaudit;

  InventoryDonutPainter({
    required this.valid,
    required this.toScan,
    required this.pendingAudit,
    required this.refused,
    required this.reaudit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - (strokeWidth / 2),
    );

    final paintValid = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintPendingAudit = Paint()
      ..color =
          const Color(0xFF6366F1) // Indigo for pending
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintToScan = Paint()
      ..color = const Color(0xFF94A3B8)
          .withOpacity(0.2) // Gray for to scan
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintReaudit = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintRefused = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background (gray circle)
    canvas.drawArc(
      rect,
      0,
      2 * 3.14159,
      false,
      Paint()
        ..color = Colors.grey.shade100
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    double startAngle = -3.14159 / 2; // Start from top

    // Valid
    if (valid > 0) {
      double sweepAngle = valid * 2 * 3.14159;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paintValid);
      startAngle += sweepAngle;
    }

    // Pending Audit
    if (pendingAudit > 0) {
      double sweepAngle = pendingAudit * 2 * 3.14159;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paintPendingAudit);
      startAngle += sweepAngle;
    }

    // To Scan
    if (toScan > 0) {
      double sweepAngle = toScan * 2 * 3.14159;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paintToScan);
      startAngle += sweepAngle;
    }

    // Reaudit
    if (reaudit > 0) {
      double sweepAngle = reaudit * 2 * 3.14159;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paintReaudit);
      startAngle += sweepAngle;
    }

    // Refused
    if (refused > 0) {
      double sweepAngle = refused * 2 * 3.14159;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paintRefused);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
