// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serve_platform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceMetadata _$DeviceMetadataFromJson(Map<String, dynamic> json) =>
    DeviceMetadata(
      platform: json['platform'] as String,
      osVersion: json['osVersion'] as String,
      sdkInt: (json['sdkInt'] as num).toInt(),
      packageName: json['packageName'] as String,
    );

Map<String, dynamic> _$DeviceMetadataToJson(DeviceMetadata instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'osVersion': instance.osVersion,
      'sdkInt': instance.sdkInt,
      'packageName': instance.packageName,
    };
