package com.john.serv_connect_mobile.platform

import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ServeMethodChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceMetadata" -> {
                result.success(
                    mapOf(
                        "platform" to "android",
                        "osVersion" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "packageName" to context.packageName,
                    ),
                )
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        private const val CHANNEL_NAME = "com.john.serv_connect_mobile/device"

        fun register(messenger: BinaryMessenger, context: Context) {
            MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler(
                ServeMethodChannelHandler(context),
            )
        }
    }
}
