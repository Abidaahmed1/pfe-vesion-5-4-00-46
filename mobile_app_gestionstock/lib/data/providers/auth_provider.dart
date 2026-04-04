import 'package:flutter/material.dart';
import '../services/keycloak_service.dart';

class AuthProvider with ChangeNotifier {
  final KeycloakService _keycloakService = KeycloakService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;

  bool _hasRequiredRole(Map<String, dynamic>? data) {
    if (data == null) return false;
    try {
      bool checkRoleList(List<String> roles) {
        return roles.any(
          (r) =>
              r.toUpperCase().replaceAll(' ', '_') == 'RESPONSABLE_LOGISTIQUE',
        );
      }

      // 1. Check realm roles
      final realmAccess = data['realm_access'] as Map<String, dynamic>? ?? {};
      final realmRoles = List<String>.from(realmAccess['roles'] ?? []);
      if (checkRoleList(realmRoles)) return true;

      // 2. Check client (resource) roles
      final resourceAccess =
          data['resource_access'] as Map<String, dynamic>? ?? {};
      for (var client in resourceAccess.values) {
        if (client is Map<String, dynamic>) {
          final clientRoles = List<String>.from(client['roles'] ?? []);
          if (checkRoleList(clientRoles)) return true;
        }
      }

      return false;
    } catch (e) {
      print("Erreur vérification rôle: $e");
      return false;
    }
  }

  Future<void> checkStatus() async {
    final String? token = await _keycloakService.getAccessToken();
    if (token != null) {
      final data = await _keycloakService.getUserInfo();
      if (_hasRequiredRole(data)) {
        _isAuthenticated = true;
        _userData = data;
      } else {
        await _keycloakService.logout();
        _isAuthenticated = false;
        _userData = null;
      }
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final success = await _keycloakService.loginWithCredentials(
      username,
      password,
    );
    if (success) {
      final data = await _keycloakService.getUserInfo();
      if (_hasRequiredRole(data)) {
        _isAuthenticated = true;
        _userData = data;
        notifyListeners();
        return true;
      } else {
        await logout();
        throw Exception("Accès refusé. Réservé aux responsables logistiques.");
      }
    }
    return false;
  }

  Future<void> logout() async {
    await _keycloakService.logout();
    _isAuthenticated = false;
    _userData = null;
    notifyListeners();
  }
}
