package com.example.xeler_impresora

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BLUETOOTH_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothEnabled" -> result.success(isBluetoothEnabled())
                else -> result.notImplemented()
            }
        }
    }

    private fun isBluetoothEnabled(): Boolean {
        return try {
            val adapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                manager?.adapter
            } else {
                @Suppress("DEPRECATION")
                BluetoothAdapter.getDefaultAdapter()
            }
            adapter?.isEnabled == true
        } catch (_: SecurityException) {
            false
        }
    }

    companion object {
        private const val BLUETOOTH_CHANNEL = "com.example.xeler_impresora/bluetooth"
    }
}
