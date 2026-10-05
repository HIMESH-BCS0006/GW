import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../config/app_config.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final void Function()? onUnauthorized;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    this.onUnauthorized,
  }) : _tokenStorage = tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (AppConfig.simulatedOffline && !options.path.contains('/auth/login')) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Simulated offline mode enabled',
          type: DioExceptionType.connectionError,
        ),
      );
    }

    options.baseUrl = AppConfig.activeBaseUrl;

    final example = AppConfig.mockExample;
    final requestPath = Uri.tryParse(options.path)?.path ?? options.path;
    if (example != null &&
        AppConfig.mockExamplePaths.any(requestPath.endsWith)) {
      options.queryParameters['__example'] = example;
    }

    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _tokenStorage.clearToken();
      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}
