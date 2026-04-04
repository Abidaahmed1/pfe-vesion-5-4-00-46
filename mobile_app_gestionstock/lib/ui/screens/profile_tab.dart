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
    final userName = auth.userData?['firstName'] != null
        ? "${auth.userData!['firstName']} ${auth.userData!['lastName']}"
        : auth.userData?['preferred_username'] ?? 'Utilisateur';
    final email = auth.userData?['email'] ?? 'Non renseigné';
    final role =
        auth.userData?['role']?.toString().replaceAll('ROLE_', '') ??
        'LOGISTIQUE';
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
                      _buildInfoCard(email, slate900),
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
      expandedHeight: 220,
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
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
                  border: Border.all(color: const Color(0xFF0D9488), width: 2),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    size: 45,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  color: textCol,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: const TextStyle(
                  color: Color(0xFF0D9488),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String email, Color textCol) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: textCol.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, "E-mail", email, textCol),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _buildInfoRow(
            Icons.business_center_outlined,
            "Position",
            "Gestionnaire de Stock",
            textCol,
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _buildInfoRow(
            Icons.verified_user_outlined,
            "Accès",
            "Activé",
            textCol,
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
  ) {
    return Row(
      children: [
        Icon(icon, color: textCol.withOpacity(0.3), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textCol.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: textCol,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, Color textCol) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final unread = notifProvider.unreadCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PARAMÈTRES",
          style: TextStyle(
            color: textCol.withOpacity(0.3),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        // Notifications → NotificationScreen
        _buildSettingsItem(
          context,
          Icons.notifications_none_rounded,
          "Notifications",
          textCol,
          badge: unread > 0 ? unread : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
        ),
        // Sécurité → Dialog
        _buildSettingsItem(
          context,
          Icons.lock_outline_rounded,
          "Changer le mot de passe",
          textCol,
          onTap: () => _showChangePasswordDialog(context),
        ),
        // Support → Dialog avec contact
        _buildSettingsItem(
          context,
          Icons.help_outline_rounded,
          "Support & Aide",
          textCol,
          onTap: () => _showSupportDialog(context),
        ),
        // À propos → Dialog version app
        _buildSettingsItem(
          context,
          Icons.info_outline_rounded,
          "À propos",
          textCol,
          onTap: () => _showAboutDialog(context),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: textCol.withOpacity(0.5), size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: textCol,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$badge",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: textCol.withOpacity(0.2)),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Changer le mot de passe",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: const Text(
          "Pour modifier votre mot de passe, connectez-vous à votre espace Keycloak via un navigateur web ou contactez votre administrateur.",
          style: TextStyle(color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Fermer",
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Compris"),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 12),
            Text(
              "Support & Aide",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSupportRow(
              Icons.email_outlined,
              "Email",
              "support@stockmaster.com",
            ),
            const SizedBox(height: 16),
            _buildSupportRow(
              Icons.phone_outlined,
              "Téléphone",
              "+213 XX XX XX XX",
            ),
            const SizedBox(height: 16),
            _buildSupportRow(
              Icons.schedule_outlined,
              "Horaires",
              "Lun–Ven : 08h00–17h00",
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0D9488)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 12),
            Text(
              "À propos",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Color(0xFFE6F7F6),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 35,
                color: Color(0xFF0D9488),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "StockMaster Mobile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Version 1.0.0",
              style: TextStyle(
                color: Color(0xFF0D9488),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Application de gestion et d'audit d'inventaire collaboratif pour les responsables logistiques.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  // ── Logout ─────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        color: Colors.redAccent.withOpacity(0.02),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _confirmLogout(context, auth),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          "SE DÉCONNECTER",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.redAccent,
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
