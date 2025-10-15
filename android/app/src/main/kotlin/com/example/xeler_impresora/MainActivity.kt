package com.example.xeler_impresora

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var enableBluetoothResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BLUETOOTH_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothEnabled" -> result.success(isBluetoothEnabled())
                "getBondedDevices" -> result.success(getBondedDevices())
                "requestEnableBluetooth" -> requestEnableBluetooth(result)
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

    private fun requestEnableBluetooth(result: MethodChannel.Result) {
        val adapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            manager?.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }

        if (adapter == null) {
            result.success(false)
            return
        }

        if (adapter.isEnabled) {
            result.success(true)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnectPermission = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED

            if (!hasConnectPermission) {
                result.success(false)
                return
            }
        }

        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        val hasHandler = intent.resolveActivity(packageManager) != null

        if (!hasHandler && Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            val enabled = try {
                adapter.enable()
            } catch (_: SecurityException) {
                false
            }
            result.success(enabled)
            return
        }

        if (!hasHandler) {
            result.success(false)
            return
        }

        enableBluetoothResult?.success(isBluetoothEnabled())
        enableBluetoothResult = result

        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, REQUEST_ENABLE_BLUETOOTH)
        } catch (_: Exception) {
            enableBluetoothResult?.success(false)
            enableBluetoothResult = null
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ENABLE_BLUETOOTH) {
            val enabled = resultCode == android.app.Activity.RESULT_OK || isBluetoothEnabled()
            enableBluetoothResult?.success(enabled)
            enableBluetoothResult = null
        }
    }

    private fun getBondedDevices(): List<Map<String, String?>> {
        val adapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            manager?.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }

        if (adapter == null || !adapter.isEnabled) {
            return emptyList()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnectPermission = ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED

            if (!hasConnectPermission) {
                return emptyList()
            }
        }

        return adapter
            .bondedDevices
            ?.map { device: BluetoothDevice ->
                mapOf(
                    "name" to device.name,
                    "address" to device.address,
                )
            }
            ?: emptyList()
    }

    companion object {
        private const val BLUETOOTH_CHANNEL = "com.example.xeler_impresora/bluetooth"
        private const val REQUEST_ENABLE_BLUETOOTH = 1001
    }
}
