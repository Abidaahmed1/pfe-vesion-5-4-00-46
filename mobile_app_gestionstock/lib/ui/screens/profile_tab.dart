import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/notification_provider.dart';
import 'notification_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName =
        auth.userData?['name'] ??
        auth.userData?['given_name'] ??
        auth.userData?['preferred_username'] ??
        'Utilisateur';
    final rawRole = auth.userData?['role']?.toString() ?? '';
    String displayRole = 'LOGISTIQUE';

    // Check keycloak roles to find the best display role
    final realmAccess =
        auth.userData?['realm_access'] as Map<String, dynamic>? ?? {};
    final roles = List<String>.from(realmAccess['roles'] ?? []);

    if (roles.any((r) => r.toUpperCase().contains('ADMIN'))) {
      displayRole = 'ADMINISTRATEUR';
    } else if (roles.any((r) => r.toUpperCase().contains('RESPONSABLE'))) {
      displayRole = 'RESPONSABLE';
    } else if (rawRole.isNotEmpty) {
      displayRole = rawRole.replaceAll('ROLE_', '');
    }

    final role = displayRole;
    const slate900 = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.05),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(userName, role, slate900),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildInfoCard(userName, role, slate900),
                      const SizedBox(height: 32),
                      _buildSettingsSection(context, slate900),
                      const SizedBox(height: 40),
                      _buildLogoutButton(context, auth),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(String name, String role, Color textCol) {
    return SliverAppBar(
      expandedHeight: 240,
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
              image: const NetworkImage(
                'https://www.transparenttextures.com/patterns/cubes.png',
              ),
              opacity: 0.03,
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0D9488).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDFA),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 45,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  color: textCol,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String userName, String role, Color textCol) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person_pin_rounded,
            "Identité",
            userName,
            textCol,
            true,
          ),
          _buildInfoRow(
            Icons.shield_outlined,
            "Accès Réseau",
            "Authentifié",
            textCol,
            true,
          ),
          _buildInfoRow(
            Icons.history_rounded,
            "État",
            "Session Active",
            textCol,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color textCol,
    bool showDivider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: Colors.grey.shade50, width: 2))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey.shade400, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textCol,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, Color textCol) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final unread = notifProvider.unreadCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PRÉFÉRENCES",
          style: TextStyle(
            color: textCol.withOpacity(0.3),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(
          context,
          Icons.notifications_none_rounded,
          "Centre de notifications",
          textCol,
          badge: unread > 0 ? unread : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    Color textCol, {
    required VoidCallback onTap,
    int? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: Color(0xFF0D9488),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          "Alertes et messages système",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$badge",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade300,
                size: 14,
              ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  // ── Logout ─────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.1)),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _confirmLogout(context, auth),
        icon: const Icon(
          Icons.power_settings_new_rounded,
          color: Color(0xFFEF4444),
          size: 20,
        ),
        label: const Text(
          "FERMER LA SESSION",
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Text(
              "Déconnexion",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir vous déconnecter ?",
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Annuler",
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Déconnecter"),
          ),
        ],
      ),
    );
  }
}
