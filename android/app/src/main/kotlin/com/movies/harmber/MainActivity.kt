package com.movies.harmber

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val systemChannel = "harmber/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── System channel ───────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, systemChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "expandNotifications" -> {
                        try {
                            @Suppress("DEPRECATION")
                            val sbService = getSystemService(Context.STATUS_BAR_SERVICE)
                            val cls    = Class.forName("android.app.StatusBarManager")
                            val method = cls.getMethod("expandSettingsPanel")
                            method.invoke(sbService)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
