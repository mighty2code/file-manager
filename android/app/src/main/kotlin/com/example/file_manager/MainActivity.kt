package com.example.file_manager

import android.annotation.SuppressLint
import android.content.Intent
import android.net.Uri
import android.os.storage.StorageManager
import androidx.annotation.NonNull
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val SDCARD_PERMISSION_RESULT_CODE = 4010
    private val CHANNEL = "com.example.file_manager/android"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "get-sdcard-permission") {
                val path = call.argument<String>("path")
                val isSuccess = getSDCardPermission(sdCardPath = path)

                if (isSuccess) {
                    result.success(true)
                } else {
                    result.error("Error", "SD Card permission request unsuccessful.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getSDCardPermission(sdCardPath: String?): Boolean {
        if (sdCardPath == null) {
            Log.e(CHANNEL, "getSDCardPermission sdCardPath is null")
            return false
        }
        val sdCard = File(sdCardPath)
        val storageManager = getSystemService(STORAGE_SERVICE) as StorageManager
        val storageVolume = storageManager.getStorageVolume(sdCard)

        // Check if storageVolume is null before proceeding
        if (storageVolume == null) {
            Log.e(CHANNEL, "getSDCardPermission: StorageVolume is null")
            return false
        }

        val intent = storageVolume.createAccessIntent(null)
        try {
            startActivityForResult(intent, SDCARD_PERMISSION_RESULT_CODE)
            return true
        } catch (e: Exception) {
            Log.e(CHANNEL, "getSDCardPermission: $e")
            return false
        }
    }

    @SuppressLint("WrongConstant")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == SDCARD_PERMISSION_RESULT_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                val uri = data.data

                // Check if uri is null before proceeding
                if (uri != null) {
                    // Grant URI permissions
                    grantUriPermission(
                        packageName, uri, Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )

                    val takeFlags = data.flags and (Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                            Intent.FLAG_GRANT_READ_URI_PERMISSION)

                    contentResolver.takePersistableUriPermission(uri, takeFlags)

                    // Send the URI to Flutter using MethodChannel
                    methodChannel!!.invokeMethod("on-sdcard-permission-resolved", getUri()?.toString())
                } else {
                    Log.e(CHANNEL, "onActivityResult: URI is null")
                }
            } else {
                Log.e(CHANNEL, "onActivityResult: Permission request failed with resultCode: $resultCode")
            }
        }
    }

    private fun getUri(): Uri? {
        val persistedUriPermissions = contentResolver.persistedUriPermissions
        if (persistedUriPermissions.isNotEmpty()) {
            // Access the first persisted URI
            val uriPermission = persistedUriPermissions[0]
            return uriPermission.uri
        }
        return null
    }
}