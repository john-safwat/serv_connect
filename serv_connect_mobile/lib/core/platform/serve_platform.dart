import 'package:json_annotation/json_annotation.dart';
import 'package:serv_connect_mobile/network/results.dart';

part 'serve_platform.g.dart';

/// Typed device metadata payload returned by the native platform channel.
@JsonSerializable()
class DeviceMetadata {
  const DeviceMetadata({
    required this.platform,
    required this.osVersion,
    required this.sdkInt,
    required this.packageName,
  });

  factory DeviceMetadata.fromJson(Map<String, dynamic> json) =>
      _$DeviceMetadataFromJson(json);

  final String platform;
  final String osVersion;
  final int sdkInt;
  final String packageName;

  Map<String, dynamic> toJson() => _$DeviceMetadataToJson(this);
}

/// Abstract facade over native Android/iOS platform channels (`CLAUDE.md §28`).
abstract class ServePlatform {
  static const String deviceChannelName = 'com.john.serv_connect_mobile/device';

  Future<ApiResult<DeviceMetadata>> getDeviceMetadata();
}
