import '../models/models.dart';

class AuthState {
  final bool isLoading;
  final bool isInitial;
  final User? user;
  final String? token;
  final String? errorMessage;
  final String? selectedDepotId;

  const AuthState({
    this.isLoading = false,
    this.isInitial = true,
    this.user,
    this.token,
    this.errorMessage,
    this.selectedDepotId,
  });

  bool get isAuthenticated => token != null && user != null;
  bool get isDriver => user?.role == Role.driver;
  bool get isLoader => user?.role == Role.loader;

  AuthState copyWith({
    bool? isLoading,
    bool? isInitial,
    User? user,
    String? token,
    String? errorMessage,
    String? selectedDepotId,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitial: isInitial ?? this.isInitial,
      user: clearUser ? null : (user ?? this.user),
      token: clearUser ? null : (token ?? this.token),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedDepotId: clearUser ? null : (selectedDepotId ?? this.selectedDepotId),
    );
  }
}
