import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/keycloak_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final KeycloakService _keycloakService = KeycloakService();
  final ApiService _apiService;

  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;
  Map<String, dynamic>? _userData;

  AuthProvider(this._apiService);

  bool get isAuthenticated => _isAuthenticated;
  bool get isCheckingAuth => _isCheckingAuth;
  Map<String, dynamic>? get userData => _userData;

  bool _hasRequiredRole(Map<String, dynamic>? data) {
    if (data == null) return false;
    try {
      bool checkRoleList(List<String> roles) {
        return roles.any((r) {
          final normalized = r.toUpperCase().replaceAll(' ', '_');
          return normalized == 'RESPONSABLE_LOGISTIQUE' ||
              normalized == 'ADMIN' ||
              normalized == 'ADMINISTRATEUR';
        });
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
    // Toujours afficher l'écran de chargement au début pour l'effet "Welcome"
    _isCheckingAuth = true;
    _isAuthenticated = false;
    notifyListeners();

    // Délai augmenté à 10 secondes pour outrepasser le gros lag du téléphone en mode debug
    await Future.delayed(const Duration(milliseconds: 10000));

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) {
      _isAuthenticated = false;
      _isCheckingAuth = false;
      notifyListeners();
      return;
    }

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

    _isCheckingAuth = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final success = await _keycloakService.loginWithCredentials(
        username,
        password,
      );
      if (success) {
        final data = await _keycloakService.getUserInfo();
        if (_hasRequiredRole(data)) {
          _isAuthenticated = true;
          _userData = data;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);

          notifyListeners();
          return true;
        } else {
          await logout();
          throw Exception("ROLE_DENIED");
        }
      }
      return false;
    } catch (e) {
      String errorMessage = "Une erreur est survenue";
      final errorStr = e.toString();

      if (errorStr.contains('AUTH_FAILED')) {
        errorMessage = "Identifiant ou mot de passe incorrect";
      } else if (errorStr.contains('NO_CONNECTION')) {
        errorMessage =
            "Impossible de contacter le serveur. Vérifiez votre connexion internet.";
      } else if (errorStr.contains('ROLE_DENIED')) {
        errorMessage =
            "Accès refusé : Vous n'avez pas les permissions nécessaires.";
      } else if (errorStr.contains('SERVER_ERROR')) {
        errorMessage =
            "Le serveur de connexion rencontre un problème technique";
      } else {
        errorMessage = errorStr.replaceAll('Exception: ', '');
      }

      throw Exception(errorMessage);
    }
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      final String? username = userData?['preferred_username'];
      if (username == null) throw Exception("Session corrompue");

      // Vérifier si l'ancien mot de passe est correct en tentant un login
      final isOldCorrect = await _keycloakService.loginWithCredentials(
        username,
        oldPassword,
      );
      if (!isOldCorrect) {
        throw Exception("Ancien mot de passe incorrect");
      }

      final response = await _apiService.put(
        '/mobile/users/password',
        data: {'newPassword': newPassword},
      );

      if (response.statusCode != 200) {
        throw Exception("Échec de la mise à jour");
      }
    } catch (e) {
      String msg = e.toString().toLowerCase();
      if (msg.contains('auth_failed') || msg.contains('incorrect')) {
        throw Exception("Ancien mot de passe incorrect");
      }
      if (msg.contains('socketexception') ||
          msg.contains('failed host lookup')) {
        throw Exception("Serveur inaccessible. Vérifiez votre connexion.");
      }
      throw Exception("Erreur lors du changement de mot de passe");
    }
  }

  Future<void> logout() async {
    await _keycloakService.logout();
    _isAuthenticated = false;
    _userData = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);

    notifyListeners();
  }
}
