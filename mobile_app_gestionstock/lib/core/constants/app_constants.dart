import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get keycloakIssuer => dotenv.env['KEYCLOAK_ISSUER'] ?? '';
  static String get keycloakClientId => dotenv.env['KEYCLOAK_CLIENT_ID'] ?? '';
  static String get keycloakRedirectUrl => dotenv.env['KEYCLOAK_REDIRECT_URL'] ?? 'com.gestionstock.app://login-callback';
  static String get webBackendUrl => dotenv.env['WEB_BACKEND_URL'] ?? '';
  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? '';
}
