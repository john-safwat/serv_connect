import Flutter
import UIKit

public final class ServeMethodChannelHandler: NSObject {
  private static let channelName = "com.john.serv_connect_mobile/device"

  public static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getDeviceMetadata":
        result([
          "platform": "ios",
          "osVersion": UIDevice.current.systemVersion,
          "sdkInt": 0,
          "packageName": Bundle.main.bundleIdentifier ?? "com.john.servConnectMobile",
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
