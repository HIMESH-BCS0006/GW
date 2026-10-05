import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:js' as js;
import '../api/api_client.dart';
import '../models/models.dart';
import '../errors/app_exception.dart';
import '../config/app_config.dart';
import 'token_storage.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthController(apiClient: apiClient, tokenStorage: tokenStorage);
});

class AuthController extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthController({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        super(const AuthState());

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, isInitial: true, clearError: true);
    try {
      String? token = Uri.base.queryParameters['token'];
      if (token == null || token.isEmpty) {
        if (Uri.base.fragment.contains('token=')) {
          try {
            final fragmentUri = Uri.parse(Uri.base.fragment);
            token = fragmentUri.queryParameters['token'];
          } catch (_) {}
        }
      }

      if (token != null && token.isNotEmpty) {
        await _tokenStorage.saveToken(token);
      } else {
        token = await _tokenStorage.getToken();
      }

      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, isInitial: false, clearUser: true);
        return;
      }

      // Restore the mock role example (mock server only), then call GET /me
      AppConfig.mockExample = await _tokenStorage.getMockExample();
      final response = await _apiClient.get('/me');
      final user = User.fromJson(Map<String, dynamic>.from(response.data as Map));

      // Determine active depot for loader
      String? activeDepot = await _tokenStorage.getActiveDepot();
      if (user.role == Role.loader) {
        if (activeDepot != null && user.depotIds.contains(activeDepot)) {
          // Keep saved valid depot
        } else if (user.depotIds.isNotEmpty) {
          activeDepot = user.depotIds.first;
          await _tokenStorage.saveActiveDepot(activeDepot);
        }
      }

      state = state.copyWith(
        isLoading: false,
        isInitial: false,
        user: user,
        token: token,
        selectedDepotId: activeDepot,
        clearError: true,
      );
    } catch (e) {
      await _tokenStorage.clearToken();
      state = state.copyWith(
        isLoading: false,
        isInitial: false,
        clearUser: true,
        errorMessage: null, // silent fallback on session restore
      );
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // MOCK ONLY: choose which Prism example to return from the username.
      final u = username.trim().toLowerCase();
      final example = u.startsWith('driver')
          ? 'driver'
          : u.startsWith('loader')
              ? 'loader'
              : 'dispatcher';
      AppConfig.mockExample = example;
      await _tokenStorage.saveMockExample(example);

      final response = await _apiClient.post(
        '/auth/login',
        data: LoginRequest(username: username.trim(), password: password).toJson(),
      );

      final loginResponse = _parseLoginResponse(response.data);
      final user = loginResponse.user;

      await _tokenStorage.saveToken(loginResponse.accessToken);

      String? activeDepot;
      if (user.role == Role.loader) {
        if (user.depotIds.length == 1) {
          activeDepot = user.depotIds.first;
          await _tokenStorage.saveActiveDepot(activeDepot);
        } else if (user.depotIds.isNotEmpty) {
          activeDepot = user.depotIds.first;
          await _tokenStorage.saveActiveDepot(activeDepot);
        }
      }

      state = state.copyWith(
        isLoading: false,
        isInitial: false,
        user: user,
        token: loginResponse.accessToken,
        selectedDepotId: activeDepot,
        clearError: true,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  LoginResponse _parseLoginResponse(Object? data) {
    if (data is! Map) {
      throw const FormatException('Invalid login response: expected an object.');
    }

    final payload = Map<String, dynamic>.from(data);
    if (payload['user'] is Map) {
      return LoginResponse.fromJson(payload);
    }

    if (!payload.containsKey('user_id')) {
      throw const FormatException(
        'Invalid login response: expected user details.',
      );
    }

    return LoginResponse.fromJson({
      ...payload,
      'user': {
        'id': payload['user_id'],
        'username': payload['username'],
        'role': payload['role'],
        'display_name': payload['display_name'],
        'depot_ids': payload['depot_ids'],
        'outlet_id': payload['outlet_id'],
        'vehicle_id': payload['vehicle_id'],
      },
    });
  }

  Future<void> selectDepot(String depotId) async {
    await _tokenStorage.saveActiveDepot(depotId);
    state = state.copyWith(selectedDepotId: depotId);
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    state = const AuthState(isInitial: false);
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      try {
        js.context.callMethod('redirectRolePortal', ['http://$host']);
      } catch (_) {}
    }
  }
}
