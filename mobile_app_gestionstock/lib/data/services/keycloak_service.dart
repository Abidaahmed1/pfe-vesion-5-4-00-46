import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/constants/app_constants.dart';

class KeycloakService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _idTokenKey = 'id_token';

  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      final tokenEndpoint =
          '${AppConstants.keycloakIssuer}/protocol/openid-connect/token';

      final response = await _dio.post(
        tokenEndpoint,
        data: {
          'grant_type': 'password',
          'client_id': AppConstants.keycloakClientId,
          'username': username,
          'password': password,
          'scope': 'openid profile email', // Removed offline_access
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status! < 500, // Handle 4xx manually
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _saveTokensDirect(data);
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        throw Exception('AUTH_FAILED');
      } else {
        throw Exception('SERVER_ERROR');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          throw Exception('NO_CONNECTION');
        }
        throw Exception('SERVER_ERROR');
      }
      rethrow;
    }
  }

  Future<void> _saveTokensDirect(Map<String, dynamic> data) async {
    await _secureStorage.write(
      key: _accessTokenKey,
      value: data['access_token'],
    );
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: data['refresh_token'],
    );
    await _secureStorage.write(key: _idTokenKey, value: data['id_token']);
  }

  Future<bool> login() async {
    try {
      final AuthorizationTokenResponse? result = await _appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              AppConstants.keycloakClientId,
              AppConstants.keycloakRedirectUrl,
              issuer: AppConstants.keycloakIssuer,
              scopes: ['openid', 'profile', 'email'], // Removed offline_access
              promptValues: ['login'],
              allowInsecureConnections: true,
            ),
          );

      if (result != null) {
        await _saveTokens(result);
        return true;
      }
      return false;
    } catch (e) {
      print('Login Error: $e');
      return false;
    }
  }

  Future<void> _saveTokens(AuthorizationTokenResponse result) async {
    await _secureStorage.write(key: _accessTokenKey, value: result.accessToken);
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: result.refreshToken,
    );
    await _secureStorage.write(key: _idTokenKey, value: result.idToken);
  }

  Future<String?> getAccessToken() async {
    String? token = await _secureStorage.read(key: _accessTokenKey);
    if (token != null && JwtDecoder.isExpired(token)) {
      return await _refreshAccessToken();
    }
    return token;
  }

  Future<String?> _refreshAccessToken() async {
    final String? refreshToken = await _secureStorage.read(
      key: _refreshTokenKey,
    );
    if (refreshToken == null) return null;

    try {
      final TokenResponse? result = await _appAuth.token(
        TokenRequest(
          AppConstants.keycloakClientId,
          AppConstants.keycloakRedirectUrl,
          issuer: AppConstants.keycloakIssuer,
          refreshToken: refreshToken,
          scopes: ['openid', 'profile', 'email'], // Removed offline_access
          allowInsecureConnections: true,
        ),
      );

      if (result != null) {
        await _secureStorage.write(
          key: _accessTokenKey,
          value: result.accessToken,
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: result.refreshToken,
        );
        return result.accessToken;
      }
    } catch (e) {
      print('Token Refresh Error: $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final String? token = await getAccessToken();
    if (token != null) {
      return JwtDecoder.decode(token);
    }
    return null;
  }
}
