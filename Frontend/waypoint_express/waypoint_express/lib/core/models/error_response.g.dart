// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ViolationImpl _$$ViolationImplFromJson(Map<String, dynamic> json) =>
    _$ViolationImpl(
      rule: json['rule'] as String,
      message: json['message'] as String,
      actual: json['actual'],
      limit: json['limit'],
    );

Map<String, dynamic> _$$ViolationImplToJson(_$ViolationImpl instance) =>
    <String, dynamic>{
      'rule': instance.rule,
      'message': instance.message,
      'actual': instance.actual,
      'limit': instance.limit,
    };

_$ErrorDetailsImpl _$$ErrorDetailsImplFromJson(Map<String, dynamic> json) =>
    _$ErrorDetailsImpl(
      violations: (json['violations'] as List<dynamic>?)
          ?.map((e) => Violation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ErrorDetailsImplToJson(_$ErrorDetailsImpl instance) =>
    <String, dynamic>{'violations': instance.violations};

_$ErrorBodyImpl _$$ErrorBodyImplFromJson(Map<String, dynamic> json) =>
    _$ErrorBodyImpl(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] == null
          ? null
          : ErrorDetails.fromJson(json['details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ErrorBodyImplToJson(_$ErrorBodyImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
    };

_$ErrorResponseImpl _$$ErrorResponseImplFromJson(Map<String, dynamic> json) =>
    _$ErrorResponseImpl(
      error: ErrorBody.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ErrorResponseImplToJson(_$ErrorResponseImpl instance) =>
    <String, dynamic>{'error': instance.error};
