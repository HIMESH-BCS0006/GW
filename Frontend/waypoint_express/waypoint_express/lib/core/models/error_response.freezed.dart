// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Violation _$ViolationFromJson(Map<String, dynamic> json) {
  return _Violation.fromJson(json);
}

/// @nodoc
mixin _$Violation {
  String get rule => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  dynamic get actual => throw _privateConstructorUsedError;
  dynamic get limit => throw _privateConstructorUsedError;

  /// Serializes this Violation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Violation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ViolationCopyWith<Violation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViolationCopyWith<$Res> {
  factory $ViolationCopyWith(Violation value, $Res Function(Violation) then) =
      _$ViolationCopyWithImpl<$Res, Violation>;
  @useResult
  $Res call({String rule, String message, dynamic actual, dynamic limit});
}

/// @nodoc
class _$ViolationCopyWithImpl<$Res, $Val extends Violation>
    implements $ViolationCopyWith<$Res> {
  _$ViolationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Violation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rule = null,
    Object? message = null,
    Object? actual = freezed,
    Object? limit = freezed,
  }) {
    return _then(
      _value.copyWith(
            rule: null == rule
                ? _value.rule
                : rule // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            actual: freezed == actual
                ? _value.actual
                : actual // ignore: cast_nullable_to_non_nullable
                      as dynamic,
            limit: freezed == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as dynamic,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ViolationImplCopyWith<$Res>
    implements $ViolationCopyWith<$Res> {
  factory _$$ViolationImplCopyWith(
    _$ViolationImpl value,
    $Res Function(_$ViolationImpl) then,
  ) = __$$ViolationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String rule, String message, dynamic actual, dynamic limit});
}

/// @nodoc
class __$$ViolationImplCopyWithImpl<$Res>
    extends _$ViolationCopyWithImpl<$Res, _$ViolationImpl>
    implements _$$ViolationImplCopyWith<$Res> {
  __$$ViolationImplCopyWithImpl(
    _$ViolationImpl _value,
    $Res Function(_$ViolationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Violation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rule = null,
    Object? message = null,
    Object? actual = freezed,
    Object? limit = freezed,
  }) {
    return _then(
      _$ViolationImpl(
        rule: null == rule
            ? _value.rule
            : rule // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        actual: freezed == actual
            ? _value.actual
            : actual // ignore: cast_nullable_to_non_nullable
                  as dynamic,
        limit: freezed == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as dynamic,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ViolationImpl implements _Violation {
  const _$ViolationImpl({
    required this.rule,
    required this.message,
    this.actual,
    this.limit,
  });

  factory _$ViolationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ViolationImplFromJson(json);

  @override
  final String rule;
  @override
  final String message;
  @override
  final dynamic actual;
  @override
  final dynamic limit;

  @override
  String toString() {
    return 'Violation(rule: $rule, message: $message, actual: $actual, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ViolationImpl &&
            (identical(other.rule, rule) || other.rule == rule) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other.actual, actual) &&
            const DeepCollectionEquality().equals(other.limit, limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    rule,
    message,
    const DeepCollectionEquality().hash(actual),
    const DeepCollectionEquality().hash(limit),
  );

  /// Create a copy of Violation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ViolationImplCopyWith<_$ViolationImpl> get copyWith =>
      __$$ViolationImplCopyWithImpl<_$ViolationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ViolationImplToJson(this);
  }
}

abstract class _Violation implements Violation {
  const factory _Violation({
    required final String rule,
    required final String message,
    final dynamic actual,
    final dynamic limit,
  }) = _$ViolationImpl;

  factory _Violation.fromJson(Map<String, dynamic> json) =
      _$ViolationImpl.fromJson;

  @override
  String get rule;
  @override
  String get message;
  @override
  dynamic get actual;
  @override
  dynamic get limit;

  /// Create a copy of Violation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ViolationImplCopyWith<_$ViolationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ErrorDetails _$ErrorDetailsFromJson(Map<String, dynamic> json) {
  return _ErrorDetails.fromJson(json);
}

/// @nodoc
mixin _$ErrorDetails {
  List<Violation>? get violations => throw _privateConstructorUsedError;

  /// Serializes this ErrorDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ErrorDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ErrorDetailsCopyWith<ErrorDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ErrorDetailsCopyWith<$Res> {
  factory $ErrorDetailsCopyWith(
    ErrorDetails value,
    $Res Function(ErrorDetails) then,
  ) = _$ErrorDetailsCopyWithImpl<$Res, ErrorDetails>;
  @useResult
  $Res call({List<Violation>? violations});
}

/// @nodoc
class _$ErrorDetailsCopyWithImpl<$Res, $Val extends ErrorDetails>
    implements $ErrorDetailsCopyWith<$Res> {
  _$ErrorDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ErrorDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? violations = freezed}) {
    return _then(
      _value.copyWith(
            violations: freezed == violations
                ? _value.violations
                : violations // ignore: cast_nullable_to_non_nullable
                      as List<Violation>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ErrorDetailsImplCopyWith<$Res>
    implements $ErrorDetailsCopyWith<$Res> {
  factory _$$ErrorDetailsImplCopyWith(
    _$ErrorDetailsImpl value,
    $Res Function(_$ErrorDetailsImpl) then,
  ) = __$$ErrorDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Violation>? violations});
}

/// @nodoc
class __$$ErrorDetailsImplCopyWithImpl<$Res>
    extends _$ErrorDetailsCopyWithImpl<$Res, _$ErrorDetailsImpl>
    implements _$$ErrorDetailsImplCopyWith<$Res> {
  __$$ErrorDetailsImplCopyWithImpl(
    _$ErrorDetailsImpl _value,
    $Res Function(_$ErrorDetailsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ErrorDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? violations = freezed}) {
    return _then(
      _$ErrorDetailsImpl(
        violations: freezed == violations
            ? _value._violations
            : violations // ignore: cast_nullable_to_non_nullable
                  as List<Violation>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ErrorDetailsImpl implements _ErrorDetails {
  const _$ErrorDetailsImpl({final List<Violation>? violations})
    : _violations = violations;

  factory _$ErrorDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ErrorDetailsImplFromJson(json);

  final List<Violation>? _violations;
  @override
  List<Violation>? get violations {
    final value = _violations;
    if (value == null) return null;
    if (_violations is EqualUnmodifiableListView) return _violations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ErrorDetails(violations: $violations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorDetailsImpl &&
            const DeepCollectionEquality().equals(
              other._violations,
              _violations,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_violations),
  );

  /// Create a copy of ErrorDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorDetailsImplCopyWith<_$ErrorDetailsImpl> get copyWith =>
      __$$ErrorDetailsImplCopyWithImpl<_$ErrorDetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ErrorDetailsImplToJson(this);
  }
}

abstract class _ErrorDetails implements ErrorDetails {
  const factory _ErrorDetails({final List<Violation>? violations}) =
      _$ErrorDetailsImpl;

  factory _ErrorDetails.fromJson(Map<String, dynamic> json) =
      _$ErrorDetailsImpl.fromJson;

  @override
  List<Violation>? get violations;

  /// Create a copy of ErrorDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorDetailsImplCopyWith<_$ErrorDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ErrorBody _$ErrorBodyFromJson(Map<String, dynamic> json) {
  return _ErrorBody.fromJson(json);
}

/// @nodoc
mixin _$ErrorBody {
  String get code => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  ErrorDetails? get details => throw _privateConstructorUsedError;

  /// Serializes this ErrorBody to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ErrorBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ErrorBodyCopyWith<ErrorBody> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ErrorBodyCopyWith<$Res> {
  factory $ErrorBodyCopyWith(ErrorBody value, $Res Function(ErrorBody) then) =
      _$ErrorBodyCopyWithImpl<$Res, ErrorBody>;
  @useResult
  $Res call({String code, String message, ErrorDetails? details});

  $ErrorDetailsCopyWith<$Res>? get details;
}

/// @nodoc
class _$ErrorBodyCopyWithImpl<$Res, $Val extends ErrorBody>
    implements $ErrorBodyCopyWith<$Res> {
  _$ErrorBodyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ErrorBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? details = freezed,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            details: freezed == details
                ? _value.details
                : details // ignore: cast_nullable_to_non_nullable
                      as ErrorDetails?,
          )
          as $Val,
    );
  }

  /// Create a copy of ErrorBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ErrorDetailsCopyWith<$Res>? get details {
    if (_value.details == null) {
      return null;
    }

    return $ErrorDetailsCopyWith<$Res>(_value.details!, (value) {
      return _then(_value.copyWith(details: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ErrorBodyImplCopyWith<$Res>
    implements $ErrorBodyCopyWith<$Res> {
  factory _$$ErrorBodyImplCopyWith(
    _$ErrorBodyImpl value,
    $Res Function(_$ErrorBodyImpl) then,
  ) = __$$ErrorBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String message, ErrorDetails? details});

  @override
  $ErrorDetailsCopyWith<$Res>? get details;
}

/// @nodoc
class __$$ErrorBodyImplCopyWithImpl<$Res>
    extends _$ErrorBodyCopyWithImpl<$Res, _$ErrorBodyImpl>
    implements _$$ErrorBodyImplCopyWith<$Res> {
  __$$ErrorBodyImplCopyWithImpl(
    _$ErrorBodyImpl _value,
    $Res Function(_$ErrorBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ErrorBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? details = freezed,
  }) {
    return _then(
      _$ErrorBodyImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        details: freezed == details
            ? _value.details
            : details // ignore: cast_nullable_to_non_nullable
                  as ErrorDetails?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ErrorBodyImpl implements _ErrorBody {
  const _$ErrorBodyImpl({
    required this.code,
    required this.message,
    this.details,
  });

  factory _$ErrorBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$ErrorBodyImplFromJson(json);

  @override
  final String code;
  @override
  final String message;
  @override
  final ErrorDetails? details;

  @override
  String toString() {
    return 'ErrorBody(code: $code, message: $message, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorBodyImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.details, details) || other.details == details));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message, details);

  /// Create a copy of ErrorBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorBodyImplCopyWith<_$ErrorBodyImpl> get copyWith =>
      __$$ErrorBodyImplCopyWithImpl<_$ErrorBodyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ErrorBodyImplToJson(this);
  }
}

abstract class _ErrorBody implements ErrorBody {
  const factory _ErrorBody({
    required final String code,
    required final String message,
    final ErrorDetails? details,
  }) = _$ErrorBodyImpl;

  factory _ErrorBody.fromJson(Map<String, dynamic> json) =
      _$ErrorBodyImpl.fromJson;

  @override
  String get code;
  @override
  String get message;
  @override
  ErrorDetails? get details;

  /// Create a copy of ErrorBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorBodyImplCopyWith<_$ErrorBodyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) {
  return _ErrorResponse.fromJson(json);
}

/// @nodoc
mixin _$ErrorResponse {
  ErrorBody get error => throw _privateConstructorUsedError;

  /// Serializes this ErrorResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ErrorResponseCopyWith<ErrorResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ErrorResponseCopyWith<$Res> {
  factory $ErrorResponseCopyWith(
    ErrorResponse value,
    $Res Function(ErrorResponse) then,
  ) = _$ErrorResponseCopyWithImpl<$Res, ErrorResponse>;
  @useResult
  $Res call({ErrorBody error});

  $ErrorBodyCopyWith<$Res> get error;
}

/// @nodoc
class _$ErrorResponseCopyWithImpl<$Res, $Val extends ErrorResponse>
    implements $ErrorResponseCopyWith<$Res> {
  _$ErrorResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? error = null}) {
    return _then(
      _value.copyWith(
            error: null == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as ErrorBody,
          )
          as $Val,
    );
  }

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ErrorBodyCopyWith<$Res> get error {
    return $ErrorBodyCopyWith<$Res>(_value.error, (value) {
      return _then(_value.copyWith(error: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ErrorResponseImplCopyWith<$Res>
    implements $ErrorResponseCopyWith<$Res> {
  factory _$$ErrorResponseImplCopyWith(
    _$ErrorResponseImpl value,
    $Res Function(_$ErrorResponseImpl) then,
  ) = __$$ErrorResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ErrorBody error});

  @override
  $ErrorBodyCopyWith<$Res> get error;
}

/// @nodoc
class __$$ErrorResponseImplCopyWithImpl<$Res>
    extends _$ErrorResponseCopyWithImpl<$Res, _$ErrorResponseImpl>
    implements _$$ErrorResponseImplCopyWith<$Res> {
  __$$ErrorResponseImplCopyWithImpl(
    _$ErrorResponseImpl _value,
    $Res Function(_$ErrorResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? error = null}) {
    return _then(
      _$ErrorResponseImpl(
        error: null == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as ErrorBody,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ErrorResponseImpl implements _ErrorResponse {
  const _$ErrorResponseImpl({required this.error});

  factory _$ErrorResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ErrorResponseImplFromJson(json);

  @override
  final ErrorBody error;

  @override
  String toString() {
    return 'ErrorResponse(error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorResponseImpl &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, error);

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorResponseImplCopyWith<_$ErrorResponseImpl> get copyWith =>
      __$$ErrorResponseImplCopyWithImpl<_$ErrorResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ErrorResponseImplToJson(this);
  }
}

abstract class _ErrorResponse implements ErrorResponse {
  const factory _ErrorResponse({required final ErrorBody error}) =
      _$ErrorResponseImpl;

  factory _ErrorResponse.fromJson(Map<String, dynamic> json) =
      _$ErrorResponseImpl.fromJson;

  @override
  ErrorBody get error;

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorResponseImplCopyWith<_$ErrorResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
