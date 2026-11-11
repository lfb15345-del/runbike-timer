package com.runbike.runbike_app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // アプリ本体（Dart側の BackgroundKeeper）からの「動かし続けて／もういいよ」を受け取る
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "runbike/background")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        try {
                            val intent = Intent(this, TimerKeepAliveService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "stop" -> {
                        try {
                            val intent = Intent(this, TimerKeepAliveService::class.java)
                            intent.action = TimerKeepAliveService.ACTION_STOP
                            startService(intent)
                        } catch (e: Exception) {
                            // すでに止まっている場合などは何もしない
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
