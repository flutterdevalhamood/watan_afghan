// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductModel {

 int? get StatusCode; String? get Message; bool? get IsSuccess; List<ProductData>? get Data;
/// Create a copy of ProductModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductModelCopyWith<ProductModel> get copyWith => _$ProductModelCopyWithImpl<ProductModel>(this as ProductModel, _$identity);

  /// Serializes this ProductModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductModel&&(identical(other.StatusCode, StatusCode) || other.StatusCode == StatusCode)&&(identical(other.Message, Message) || other.Message == Message)&&(identical(other.IsSuccess, IsSuccess) || other.IsSuccess == IsSuccess)&&const DeepCollectionEquality().equals(other.Data, Data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,StatusCode,Message,IsSuccess,const DeepCollectionEquality().hash(Data));

@override
String toString() {
  return 'ProductModel(StatusCode: $StatusCode, Message: $Message, IsSuccess: $IsSuccess, Data: $Data)';
}


}

/// @nodoc
abstract mixin class $ProductModelCopyWith<$Res>  {
  factory $ProductModelCopyWith(ProductModel value, $Res Function(ProductModel) _then) = _$ProductModelCopyWithImpl;
@useResult
$Res call({
 int? StatusCode, String? Message, bool? IsSuccess, List<ProductData>? Data
});




}
/// @nodoc
class _$ProductModelCopyWithImpl<$Res>
    implements $ProductModelCopyWith<$Res> {
  _$ProductModelCopyWithImpl(this._self, this._then);

  final ProductModel _self;
  final $Res Function(ProductModel) _then;

/// Create a copy of ProductModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? StatusCode = freezed,Object? Message = freezed,Object? IsSuccess = freezed,Object? Data = freezed,}) {
  return _then(_self.copyWith(
StatusCode: freezed == StatusCode ? _self.StatusCode : StatusCode // ignore: cast_nullable_to_non_nullable
as int?,Message: freezed == Message ? _self.Message : Message // ignore: cast_nullable_to_non_nullable
as String?,IsSuccess: freezed == IsSuccess ? _self.IsSuccess : IsSuccess // ignore: cast_nullable_to_non_nullable
as bool?,Data: freezed == Data ? _self.Data : Data // ignore: cast_nullable_to_non_nullable
as List<ProductData>?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ProductModel implements ProductModel {
  const _ProductModel({this.StatusCode, this.Message, this.IsSuccess, final  List<ProductData>? Data}): _Data = Data;
  factory _ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);

@override final  int? StatusCode;
@override final  String? Message;
@override final  bool? IsSuccess;
 final  List<ProductData>? _Data;
@override List<ProductData>? get Data {
  final value = _Data;
  if (value == null) return null;
  if (_Data is EqualUnmodifiableListView) return _Data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ProductModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductModelCopyWith<_ProductModel> get copyWith => __$ProductModelCopyWithImpl<_ProductModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductModel&&(identical(other.StatusCode, StatusCode) || other.StatusCode == StatusCode)&&(identical(other.Message, Message) || other.Message == Message)&&(identical(other.IsSuccess, IsSuccess) || other.IsSuccess == IsSuccess)&&const DeepCollectionEquality().equals(other._Data, _Data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,StatusCode,Message,IsSuccess,const DeepCollectionEquality().hash(_Data));

@override
String toString() {
  return 'ProductModel(StatusCode: $StatusCode, Message: $Message, IsSuccess: $IsSuccess, Data: $Data)';
}


}

/// @nodoc
abstract mixin class _$ProductModelCopyWith<$Res> implements $ProductModelCopyWith<$Res> {
  factory _$ProductModelCopyWith(_ProductModel value, $Res Function(_ProductModel) _then) = __$ProductModelCopyWithImpl;
@override @useResult
$Res call({
 int? StatusCode, String? Message, bool? IsSuccess, List<ProductData>? Data
});




}
/// @nodoc
class __$ProductModelCopyWithImpl<$Res>
    implements _$ProductModelCopyWith<$Res> {
  __$ProductModelCopyWithImpl(this._self, this._then);

  final _ProductModel _self;
  final $Res Function(_ProductModel) _then;

/// Create a copy of ProductModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? StatusCode = freezed,Object? Message = freezed,Object? IsSuccess = freezed,Object? Data = freezed,}) {
  return _then(_ProductModel(
StatusCode: freezed == StatusCode ? _self.StatusCode : StatusCode // ignore: cast_nullable_to_non_nullable
as int?,Message: freezed == Message ? _self.Message : Message // ignore: cast_nullable_to_non_nullable
as String?,IsSuccess: freezed == IsSuccess ? _self.IsSuccess : IsSuccess // ignore: cast_nullable_to_non_nullable
as bool?,Data: freezed == Data ? _self._Data : Data // ignore: cast_nullable_to_non_nullable
as List<ProductData>?,
  ));
}


}


/// @nodoc
mixin _$ProductData {

 int? get id; String? get Name;
/// Create a copy of ProductData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductDataCopyWith<ProductData> get copyWith => _$ProductDataCopyWithImpl<ProductData>(this as ProductData, _$identity);

  /// Serializes this ProductData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductData&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'ProductData(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class $ProductDataCopyWith<$Res>  {
  factory $ProductDataCopyWith(ProductData value, $Res Function(ProductData) _then) = _$ProductDataCopyWithImpl;
@useResult
$Res call({
 int? id, String? Name
});




}
/// @nodoc
class _$ProductDataCopyWithImpl<$Res>
    implements $ProductDataCopyWith<$Res> {
  _$ProductDataCopyWithImpl(this._self, this._then);

  final ProductData _self;
  final $Res Function(ProductData) _then;

/// Create a copy of ProductData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ProductData implements ProductData {
  const _ProductData({this.id, this.Name});
  factory _ProductData.fromJson(Map<String, dynamic> json) => _$ProductDataFromJson(json);

@override final  int? id;
@override final  String? Name;

/// Create a copy of ProductData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductDataCopyWith<_ProductData> get copyWith => __$ProductDataCopyWithImpl<_ProductData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductData&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'ProductData(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class _$ProductDataCopyWith<$Res> implements $ProductDataCopyWith<$Res> {
  factory _$ProductDataCopyWith(_ProductData value, $Res Function(_ProductData) _then) = __$ProductDataCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? Name
});




}
/// @nodoc
class __$ProductDataCopyWithImpl<$Res>
    implements _$ProductDataCopyWith<$Res> {
  __$ProductDataCopyWithImpl(this._self, this._then);

  final _ProductData _self;
  final $Res Function(_ProductData) _then;

/// Create a copy of ProductData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_ProductData(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
