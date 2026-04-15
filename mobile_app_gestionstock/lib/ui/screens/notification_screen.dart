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
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0D9488);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    const textColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Provider.of<NotificationProvider>(
              context,
              listen: false,
            ).markAllAsRead(),
            child: const Text(
              "Tout lire",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState(primaryColor, textColor);
          }

          final grouped = _groupNotifications(provider.notifications);

          return RefreshIndicator(
            onRefresh: provider.fetchNotifications,
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final item = grouped[index];
                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: 24,
                      bottom: 12,
                      left: 4,
                    ),
                    child: Text(
                      item.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  );
                }
                return _buildPremiumNotifCard(
                  item,
                  provider,
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

  List<dynamic> _groupNotifications(List<dynamic> notifications) {
    List<dynamic> grouped = [];
    String lastHeader = "";
    final now = DateTime.now();

    for (var notif in notifications) {
      try {
        final date = DateTime.parse(notif['date']);
        String header = "";

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          header = "Aujourd'hui";
        } else if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day - 1) {
          header = "Hier";
        } else {
          header = DateFormat('MMMM yyyy', 'fr_FR').format(date);
        }

        if (header != lastHeader) {
          grouped.add(header);
          lastHeader = header;
        }
        grouped.add(notif);
      } catch (e) {
        grouped.add(notif);
      }
    }
    return grouped;
  }

  Widget _buildPremiumNotifCard(
    dynamic notif,
    NotificationProvider provider,
    Color primaryColor,
    Color textColor,
  ) {
    final bool isRead = notif['lu'] ?? false;
    final typeColor = _getTypeColor(notif['type']);
    final date = DateTime.parse(notif['date']);

    return GestureDetector(
      onTap: () => provider.markAsRead(notif['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? Colors.grey.shade100 : typeColor.withOpacity(0.2),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isRead ? 0.02 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(notif['type']),
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif['titre'],
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                              color: textColor,
                              fontSize: 15,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif['message'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      DateFormat('HH:mm').format(date),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: primaryColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Tout est à jour",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Vous n'avez pas de nouvelles notifications.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'SUCCESS':
        return const Color(0xFF10B981);
      case 'ERROR':
        return const Color(0xFFEF4444);
      case 'WARNING':
        return const Color(0xFFF59E0B);
      case 'INFO':
        return const Color(0xFF3B82F6);
      case 'RUPTURE_STOCK':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF0D9488);
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'SUCCESS':
        return Icons.check_circle_outline_rounded;
      case 'ERROR':
        return Icons.error_outline_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'RUPTURE_STOCK':
        return Icons.trending_down_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}
