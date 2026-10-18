package com.john.serv_connect_mobile

import com.john.serv_connect_mobile.platform.ServeMethodChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ServeMethodChannelHandler.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
    }
}
