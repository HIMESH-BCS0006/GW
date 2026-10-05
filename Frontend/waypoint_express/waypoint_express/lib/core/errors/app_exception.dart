import 'package:dio/dio.dart';
import '../models/error_response.dart';

class AppException implements Exception {
  final String code;
  final String message;
  final String userFriendlyMessage;
  final ErrorDetails? details;
  final int? statusCode;

  const AppException({
    required this.code,
    required this.message,
    required this.userFriendlyMessage,
    this.details,
    this.statusCode,
  });

  factory AppException.fromDioException(DioException dioException) {
    if (dioException.response?.data != null) {
      try {
        final data = dioException.response!.data;
        if (data is Map<String, dynamic> && data.containsKey('error')) {
          final errorBody = ErrorResponse.fromJson(data).error;
          return AppException(
            code: errorBody.code,
            message: errorBody.message,
            userFriendlyMessage: mapErrorCodeToMessage(errorBody.code, errorBody.message, errorBody.details),
            details: errorBody.details,
            statusCode: dioException.response?.statusCode,
          );
        }
      } catch (_) {
        // Fallback to HTTP status handling if parsing fails
      }
    }

    final statusCode = dioException.response?.statusCode;
    if (statusCode == 401) {
      return const AppException(
        code: 'UNAUTHORIZED',
        message: 'Invalid username or password',
        userFriendlyMessage: 'Session expired or invalid credentials. Please log in again.',
        statusCode: 401,
      );
    } else if (statusCode == 403) {
      return const AppException(
        code: 'FORBIDDEN_SCOPE',
        message: 'Forbidden scope access',
        userFriendlyMessage: 'Access denied: You do not have permission for this depot or vehicle.',
        statusCode: 403,
      );
    } else if (statusCode == 409) {
      return const AppException(
        code: 'PLAN_CHANGED',
        message: 'Conflict: Plan changed or invalid state transition',
        userFriendlyMessage: 'The plan was updated. Please refresh and check latest plan version.',
        statusCode: 409,
      );
    }

    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          code: 'TIMEOUT',
          message: 'Connection timed out',
          userFriendlyMessage: 'The server took too long to respond. Action queued locally if offline.',
        );
      case DioExceptionType.connectionError:
        return const AppException(
          code: 'NETWORK_ERROR',
          message: 'Network connection failed',
          userFriendlyMessage: 'No internet connection. Operating in offline mode.',
        );
      default:
        return AppException(
          code: 'UNKNOWN',
          message: dioException.message ?? 'An unexpected error occurred',
          userFriendlyMessage: 'Something went wrong. Please try again.',
          statusCode: statusCode,
        );
    }
  }

  static String mapErrorCodeToMessage(String code, String serverMessage, ErrorDetails? details) {
    switch (code) {
      case 'PLAN_CHANGED':
        return 'The delivery plan has been updated by the dispatcher. Please refresh your screen.';
      case 'STALE_PLAN_VERSION':
        return 'Plan changed! Your version is outdated. Please refresh to load the current version.';
      case 'OPEN_SHORTFALL':
        return 'Cannot confirm load: There is an open shortfall reported that must be resolved first.';
      case 'INVALID_TRANSITION':
        return 'Action not allowed at this stage: $serverMessage';
      case 'FORBIDDEN_SCOPE':
        return 'Access denied: You do not have access to this depot or vehicle.';
      case 'UNAUTHORIZED':
        return 'Incorrect username or password. Please check your credentials.';
      case 'CONSTRAINT_VIOLATION':
        if (details?.violations != null && details!.violations!.isNotEmpty) {
          final v = details.violations!.first;
          return 'Rule violation (${v.rule}): ${v.message}';
        }
        return 'Validation constraint violation: $serverMessage';
      case 'NOT_OPERATING_DAY':
        return 'Waypoint does not operate on this selected date.';
      default:
        return serverMessage.isNotEmpty ? serverMessage : 'An error occurred ($code).';
    }
  }

  @override
  String toString() => 'AppException(code: $code, message: $userFriendlyMessage)';
}
