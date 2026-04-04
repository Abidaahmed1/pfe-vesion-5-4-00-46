import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0D9488);
    const slate900 = Color(0xFF0F172A);
    const slate600 = Color(0xFF475569);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: slate900,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => Provider.of<NotificationProvider>(context, listen: false).markAllAsRead(),
            child: const Text("Tout lire", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.notifications.isEmpty) {
            return _buildEmptyState(slate900);
          }

          return RefreshIndicator(
            onRefresh: provider.fetchNotifications,
            color: primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final notif = provider.notifications[index];
                return _buildNotifItem(notif, provider, primaryColor, slate900, slate600);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotifItem(dynamic notif, NotificationProvider provider, Color primaryColor, Color slate900, Color slate600) {
    final bool isRead = notif['lu'] ?? false;
    final DateTime date = DateTime.parse(notif['date']);

    return ListTile(
      onTap: () => provider.markAsRead(notif['id']),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      tileColor: isRead ? Colors.transparent : primaryColor.withOpacity(0.03),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _getTypeColor(notif['type']).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(_getTypeIcon(notif['type']), color: _getTypeColor(notif['type']), size: 20),
      ),
      title: Text(
        notif['titre'],
        style: TextStyle(
          fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
          color: slate900,
          fontSize: 15,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(notif['message'], style: TextStyle(color: slate600, fontSize: 13, height: 1.4)),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd/MM à HH:mm').format(date),
            style: TextStyle(color: slate600.withOpacity(0.5), fontSize: 11),
          ),
        ],
      ),
      trailing: isRead 
        ? null 
        : Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
    );
  }

  Widget _buildEmptyState(Color slate900) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: slate900.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text("Aucune notification", style: TextStyle(color: slate900, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text("Vous êtes à jour !", style: TextStyle(color: slate900.withOpacity(0.4))),
        ],
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'SUCCESS': return const Color(0xFF10B981);
      case 'ERROR': return const Color(0xFFEF4444);
      case 'WARNING': return const Color(0xFFF59E0B);
      case 'INFO': return const Color(0xFF3B82F6);
      case 'RUPTURE_STOCK': return const Color(0xFF8B5CF6);
      default: return const Color(0xFF64748B);
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'SUCCESS': return Icons.check_circle_outline_rounded;
      case 'ERROR': return Icons.error_outline_rounded;
      case 'WARNING': return Icons.warning_amber_rounded;
      case 'RUPTURE_STOCK': return Icons.trending_down_rounded;
      default: return Icons.notifications_none_rounded;
    }
  }
}
