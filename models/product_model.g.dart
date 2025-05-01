// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductModel _$ProductModelFromJson(Map<String, dynamic> json) =>
    _ProductModel(
      StatusCode: (json['StatusCode'] as num?)?.toInt(),
      Message: json['Message'] as String?,
      IsSuccess: json['IsSuccess'] as bool?,
      Data:
          (json['Data'] as List<dynamic>?)
              ?.map((e) => ProductData.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$ProductModelToJson(_ProductModel instance) =>
    <String, dynamic>{
      'StatusCode': instance.StatusCode,
      'Message': instance.Message,
      'IsSuccess': instance.IsSuccess,
      'Data': instance.Data,
    };

_ProductData _$ProductDataFromJson(Map<String, dynamic> json) => _ProductData(
  id: (json['id'] as num?)?.toInt(),
  Name: json['Name'] as String?,
);

Map<String, dynamic> _$ProductDataToJson(_ProductData instance) =>
    <String, dynamic>{'id': instance.id, 'Name': instance.Name};
