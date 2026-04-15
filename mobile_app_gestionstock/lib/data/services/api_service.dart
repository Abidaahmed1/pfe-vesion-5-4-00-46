import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import 'keycloak_service.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.backendUrl));
  final KeycloakService _keycloakService = KeycloakService();

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final String? token = await _keycloakService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token might be expired, but KeycloakService already handles refreshing on getAccessToken.
            // If it still returns 401, maybe logout or redirect to login.
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  String get baseUrl => _dio.options.baseUrl;
}
