// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'load_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LoadListResponse _$LoadListResponseFromJson(Map<String, dynamic> json) {
  return _LoadListResponse.fromJson(json);
}

/// @nodoc
mixin _$LoadListResponse {
  @JsonKey(name: 'plan_version')
  int get planVersion => throw _privateConstructorUsedError;
  TripCard get trip => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_sequence')
  List<StopDetail> get deliverySequence => throw _privateConstructorUsedError;
  @JsonKey(name: 'reverse_load_order')
  List<StopDetail> get reverseLoadOrder => throw _privateConstructorUsedError;

  /// Serializes this LoadListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoadListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoadListResponseCopyWith<LoadListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoadListResponseCopyWith<$Res> {
  factory $LoadListResponseCopyWith(
    LoadListResponse value,
    $Res Function(LoadListResponse) then,
  ) = _$LoadListResponseCopyWithImpl<$Res, LoadListResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'plan_version') int planVersion,
    TripCard trip,
    @JsonKey(name: 'delivery_sequence') List<StopDetail> deliverySequence,
    @JsonKey(name: 'reverse_load_order') List<StopDetail> reverseLoadOrder,
  });

  $TripCardCopyWith<$Res> get trip;
}

/// @nodoc
class _$LoadListResponseCopyWithImpl<$Res, $Val extends LoadListResponse>
    implements $LoadListResponseCopyWith<$Res> {
  _$LoadListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoadListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? planVersion = null,
    Object? trip = null,
    Object? deliverySequence = null,
    Object? reverseLoadOrder = null,
  }) {
    return _then(
      _value.copyWith(
            planVersion: null == planVersion
                ? _value.planVersion
                : planVersion // ignore: cast_nullable_to_non_nullable
                      as int,
            trip: null == trip
                ? _value.trip
                : trip // ignore: cast_nullable_to_non_nullable
                      as TripCard,
            deliverySequence: null == deliverySequence
                ? _value.deliverySequence
                : deliverySequence // ignore: cast_nullable_to_non_nullable
                      as List<StopDetail>,
            reverseLoadOrder: null == reverseLoadOrder
                ? _value.reverseLoadOrder
                : reverseLoadOrder // ignore: cast_nullable_to_non_nullable
                      as List<StopDetail>,
          )
          as $Val,
    );
  }

  /// Create a copy of LoadListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TripCardCopyWith<$Res> get trip {
    return $TripCardCopyWith<$Res>(_value.trip, (value) {
      return _then(_value.copyWith(trip: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LoadListResponseImplCopyWith<$Res>
    implements $LoadListResponseCopyWith<$Res> {
  factory _$$LoadListResponseImplCopyWith(
    _$LoadListResponseImpl value,
    $Res Function(_$LoadListResponseImpl) then,
  ) = __$$LoadListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'plan_version') int planVersion,
    TripCard trip,
    @JsonKey(name: 'delivery_sequence') List<StopDetail> deliverySequence,
    @JsonKey(name: 'reverse_load_order') List<StopDetail> reverseLoadOrder,
  });

  @override
  $TripCardCopyWith<$Res> get trip;
}

/// @nodoc
class __$$LoadListResponseImplCopyWithImpl<$Res>
    extends _$LoadListResponseCopyWithImpl<$Res, _$LoadListResponseImpl>
    implements _$$LoadListResponseImplCopyWith<$Res> {
  __$$LoadListResponseImplCopyWithImpl(
    _$LoadListResponseImpl _value,
    $Res Function(_$LoadListResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoadListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? planVersion = null,
    Object? trip = null,
    Object? deliverySequence = null,
    Object? reverseLoadOrder = null,
  }) {
    return _then(
      _$LoadListResponseImpl(
        planVersion: null == planVersion
            ? _value.planVersion
            : planVersion // ignore: cast_nullable_to_non_nullable
                  as int,
        trip: null == trip
            ? _value.trip
            : trip // ignore: cast_nullable_to_non_nullable
                  as TripCard,
        deliverySequence: null == deliverySequence
            ? _value._deliverySequence
            : deliverySequence // ignore: cast_nullable_to_non_nullable
                  as List<StopDetail>,
        reverseLoadOrder: null == reverseLoadOrder
            ? _value._reverseLoadOrder
            : reverseLoadOrder // ignore: cast_nullable_to_non_nullable
                  as List<StopDetail>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoadListResponseImpl implements _LoadListResponse {
  const _$LoadListResponseImpl({
    @JsonKey(name: 'plan_version') required this.planVersion,
    required this.trip,
    @JsonKey(name: 'delivery_sequence')
    required final List<StopDetail> deliverySequence,
    @JsonKey(name: 'reverse_load_order')
    required final List<StopDetail> reverseLoadOrder,
  }) : _deliverySequence = deliverySequence,
       _reverseLoadOrder = reverseLoadOrder;

  factory _$LoadListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoadListResponseImplFromJson(json);

  @override
  @JsonKey(name: 'plan_version')
  final int planVersion;
  @override
  final TripCard trip;
  final List<StopDetail> _deliverySequence;
  @override
  @JsonKey(name: 'delivery_sequence')
  List<StopDetail> get deliverySequence {
    if (_deliverySequence is EqualUnmodifiableListView)
      return _deliverySequence;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deliverySequence);
  }

  final List<StopDetail> _reverseLoadOrder;
  @override
  @JsonKey(name: 'reverse_load_order')
  List<StopDetail> get reverseLoadOrder {
    if (_reverseLoadOrder is EqualUnmodifiableListView)
      return _reverseLoadOrder;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reverseLoadOrder);
  }

  @override
  String toString() {
    return 'LoadListResponse(planVersion: $planVersion, trip: $trip, deliverySequence: $deliverySequence, reverseLoadOrder: $reverseLoadOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadListResponseImpl &&
            (identical(other.planVersion, planVersion) ||
                other.planVersion == planVersion) &&
            (identical(other.trip, trip) || other.trip == trip) &&
            const DeepCollectionEquality().equals(
              other._deliverySequence,
              _deliverySequence,
            ) &&
            const DeepCollectionEquality().equals(
              other._reverseLoadOrder,
              _reverseLoadOrder,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    planVersion,
    trip,
    const DeepCollectionEquality().hash(_deliverySequence),
    const DeepCollectionEquality().hash(_reverseLoadOrder),
  );

  /// Create a copy of LoadListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadListResponseImplCopyWith<_$LoadListResponseImpl> get copyWith =>
      __$$LoadListResponseImplCopyWithImpl<_$LoadListResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LoadListResponseImplToJson(this);
  }
}

abstract class _LoadListResponse implements LoadListResponse {
  const factory _LoadListResponse({
    @JsonKey(name: 'plan_version') required final int planVersion,
    required final TripCard trip,
    @JsonKey(name: 'delivery_sequence')
    required final List<StopDetail> deliverySequence,
    @JsonKey(name: 'reverse_load_order')
    required final List<StopDetail> reverseLoadOrder,
  }) = _$LoadListResponseImpl;

  factory _LoadListResponse.fromJson(Map<String, dynamic> json) =
      _$LoadListResponseImpl.fromJson;

  @override
  @JsonKey(name: 'plan_version')
  int get planVersion;
  @override
  TripCard get trip;
  @override
  @JsonKey(name: 'delivery_sequence')
  List<StopDetail> get deliverySequence;
  @override
  @JsonKey(name: 'reverse_load_order')
  List<StopDetail> get reverseLoadOrder;

  /// Create a copy of LoadListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadListResponseImplCopyWith<_$LoadListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
