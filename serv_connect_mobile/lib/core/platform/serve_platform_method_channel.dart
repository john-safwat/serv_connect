import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/platform/serve_platform.dart';
import 'package:serv_connect_mobile/network/errors.dart';
import 'package:serv_connect_mobile/network/results.dart';

/// `MethodChannel` implementation of [ServePlatform] (`CLAUDE.md §28`).
///
/// Catches [PlatformException] and maps it into `Failure(exception: PlatformError)`.
@LazySingleton(as: ServePlatform)
class ServePlatformMethodChannel implements ServePlatform {
  ServePlatformMethodChannel()
    : _channel = const MethodChannel(ServePlatform.deviceChannelName);

  @visibleForTesting
  ServePlatformMethodChannel.test(this._channel);

  final MethodChannel _channel;

  @override
  Future<ApiResult<DeviceMetadata>> getDeviceMetadata() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getDeviceMetadata',
      );
      if (raw == null) {
        return const Failure<DeviceMetadata>(
          exception: PlatformError(
            code: 'EMPTY_RESPONSE',
            message: 'Native channel returned null metadata.',
          ),
          message: 'Native channel returned null metadata.',
        );
      }
      return Success<DeviceMetadata>(DeviceMetadata.fromJson(raw));
    } on PlatformException catch (e) {
      return Failure<DeviceMetadata>(
        exception: PlatformError(code: e.code, message: e.message),
        message: e.message ?? 'Platform channel error',
      );
    }
  }
}
