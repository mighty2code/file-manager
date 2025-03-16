package com.example.file_manager

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "file_manager/android"
    private var methodChannel: MethodChannel? = null

    // Use StartActivityForResult to get both the Uri and the Intent flags needed for persisting permission.
    private val openDocumentTreeLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            if (result.resultCode == RESULT_OK && result.data != null) {
                val data = result.data
                val uri: Uri? = data?.data
                if (uri != null) {
                    // Get the permission flags from the returned intent
                    val takeFlags = data.flags and
                        (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    try {
                        // Persist the permission so it survives device reboots
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                            contentResolver.takePersistableUriPermission(uri, takeFlags)
                        }
                        // Notify Flutter that permission was granted and pass the URI as a string.
                        methodChannel?.invokeMethod("on-sdcard-permission-resolved", uri.toString())
                    } catch (e: SecurityException) {
                        Log.e(CHANNEL, "Failed to take persistable URI permission: $e")
                    }
                } else {
                    Log.e(CHANNEL, "Document picker result: URI is null")
                }
            } else {
                Log.e(CHANNEL, "Document picker result: Permission request failed with resultCode: ${result.resultCode}")
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "get-sdcard-permission" -> {
                    // Optional: log the requested sdCardPath if provided.
                    val sdCardPath = call.argument<String>("path")
                    if (sdCardPath == null) {
                        Log.e(CHANNEL, "get-sdcard-permission: sdCardPath is null")
                    } else {
                        Log.i(CHANNEL, "get-sdcard-permission: requested path = $sdCardPath")
                    }
                    try {
                        // Create the intent to launch the system document picker.
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                                // Optionally show advanced devices (remove if not needed)
                                putExtra("android.content.extra.SHOW_ADVANCED", true)
                            }
                        } else {
                            TODO("VERSION.SDK_INT < LOLLIPOP")
                        }
                        openDocumentTreeLauncher.launch(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(CHANNEL, "get-sdcard-permission exception: $e")
                        result.error("Error", "SD Card permission request unsuccessful.", null)
                    }
                }
                
                "sdcard-create-file" -> {
                    val baseUri = call.argument<String>("base-uri")
                    val destinationPath = call.argument<String>("destination")
                    val name = call.argument<String>("name")
                    val mimeType = call.argument<String>("mimeType") ?: "text/plain"
                    if (destinationPath == null || name == null) {
                        result.error("InvalidArguments", "Missing destination or name", null)
                        return@setMethodCallHandler
                    }
                    val isFileCreated = SDCardUtils.createFile(this, Uri.parse(baseUri), destinationPath, name, mimeType)
                    if (isFileCreated != null) {
                        result.success(isFileCreated.toString())
                    } else {
                        result.error("CreateFileFailed", "Failed to create file", null)
                    }
                }
                "sdcard-create-directory" -> {
                    val baseUri = call.argument<String>("base-uri")
                    val destinationPath = call.argument<String>("destination")
                    val name = call.argument<String>("name")
                    if (destinationPath == null || name == null) {
                        result.error("InvalidArguments", "Missing destination or name", null)
                        return@setMethodCallHandler
                    }
                    val isDirCreated = SDCardUtils.createDirectory(this, Uri.parse(baseUri), destinationPath, name)
                    if (isDirCreated != null) {
                        result.success(isDirCreated.uri.toString())
                    } else {
                        result.error("CreateDirectoryFailed", "Failed to create directory", null)
                    }
                }
                "sdcard-clone-file" -> {
                    val baseUri = call.argument<String>("base-uri")
                    val sourcePath = call.argument<String>("source")
                    val destinationPath = call.argument<String>("destination")
                    if (sourcePath == null || destinationPath == null) {
                        result.error("InvalidArguments", "Missing source or destination", null)
                        return@setMethodCallHandler
                    }
                    val success = SDCardUtils.cloneFile(this, Uri.parse(baseUri), sourcePath, destinationPath)
                    result.success(success)
                }
                "sdcard-clone-directory" -> {
                    val baseUri = call.argument<String>("base-uri")
                    val sourcePath = call.argument<String>("source")
                    val destinationPath = call.argument<String>("destination")
                    if (sourcePath == null || destinationPath == null) {
                        result.error("InvalidArguments", "Missing source or destination", null)
                        return@setMethodCallHandler
                    }
                    val success = SDCardUtils.cloneDirectory(this, Uri.parse(baseUri), sourcePath, destinationPath)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Returns the first persisted URI permission that appears to be a tree URI.
     */
    private fun getPersistedSDCardUri(): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            contentResolver.persistedUriPermissions.firstOrNull { uriPermission ->
                uriPermission.uri.toString().contains("tree")
            }?.uri
        } else {
            TODO("VERSION.SDK_INT < KITKAT")
        }
    }
}