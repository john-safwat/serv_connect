import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_connect_mobile/core/platform/serve_platform.dart';
import 'package:serv_connect_mobile/core/platform/serve_platform_method_channel.dart';
import 'package:serv_connect_mobile/network/errors.dart';
import 'package:serv_connect_mobile/network/results.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ServePlatform.deviceChannelName);
  late ServePlatformMethodChannel platform;

  setUp(() {
    platform = ServePlatformMethodChannel.test(channel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('ServePlatformMethodChannel', () {
    test('getDeviceMetadata_whenNativeSucceeds_returnsSuccessDto', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return <String, dynamic>{
              'platform': 'android',
              'osVersion': '15',
              'sdkInt': 35,
              'packageName': 'com.john.serv_connect_mobile.dev',
            };
          });

      final result = await platform.getDeviceMetadata();
      expect(result, isA<Success<DeviceMetadata>>());
      final data = (result as Success<DeviceMetadata>).data!;
      expect(data.platform, 'android');
      expect(data.sdkInt, 35);
      expect(data.toJson()['packageName'], 'com.john.serv_connect_mobile.dev');
    });

    test(
      'getDeviceMetadata_whenPlatformExceptionThrown_mapsToPlatformError',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              throw PlatformException(
                code: 'ERR_NATIVE',
                message: 'Native failed',
              );
            });

        final result = await platform.getDeviceMetadata();
        expect(result, isA<Failure<DeviceMetadata>>());
        final failure = result as Failure<DeviceMetadata>;
        expect(failure.exception, isA<PlatformError>());
      },
    );
  });
}
