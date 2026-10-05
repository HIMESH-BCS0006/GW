import 'package:freezed_annotation/freezed_annotation.dart';

part 'error_response.freezed.dart';
part 'error_response.g.dart';

@freezed
class Violation with _$Violation {
  const factory Violation({
    required String rule,
    required String message,
    dynamic actual,
    dynamic limit,
  }) = _Violation;

  factory Violation.fromJson(Map<String, dynamic> json) => _$ViolationFromJson(json);
}

@freezed
class ErrorDetails with _$ErrorDetails {
  const factory ErrorDetails({
    List<Violation>? violations,
  }) = _ErrorDetails;

  factory ErrorDetails.fromJson(Map<String, dynamic> json) =>
      _$ErrorDetailsFromJson(json);
}

@freezed
class ErrorBody with _$ErrorBody {
  const factory ErrorBody({
    required String code,
    required String message,
    ErrorDetails? details,
  }) = _ErrorBody;

  factory ErrorBody.fromJson(Map<String, dynamic> json) => _$ErrorBodyFromJson(json);
}

@freezed
class ErrorResponse with _$ErrorResponse {
  const factory ErrorResponse({
    required ErrorBody error,
  }) = _ErrorResponse;

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
}
