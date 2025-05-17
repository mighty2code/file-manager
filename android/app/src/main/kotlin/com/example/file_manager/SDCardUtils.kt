package com.example.file_manager

import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import io.flutter.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import java.io.File
import java.io.InputStream
import java.io.OutputStream

object SDCardUtils {
    private const val LOG_TAG = "SDCardUtils"

    fun createFile(activity: FlutterFragmentActivity, baseUri: Uri, destinationPath: String, name: String, mimeType: String): Uri? {
        val destinationUri = getDocumentUriForPath(activity, baseUri, destinationPath)
        val pickedDir = DocumentFile.fromTreeUri(activity, destinationUri)
        if (pickedDir != null && pickedDir.isDirectory) {
            if (pickedDir.findFile(name) != null) return null
            val newFile = pickedDir.createFile(mimeType, name)
            return newFile?.uri
        }
        return null
    }

    fun createDirectory(activity: FlutterFragmentActivity, baseUri: Uri, destinationPath: String, name: String): DocumentFile? {
         val destinationUri = getDocumentUriForPath(activity, baseUri, destinationPath)
         val pickedDir = DocumentFile.fromTreeUri(activity, destinationUri)
         if (pickedDir != null && pickedDir.isDirectory) {
             if (pickedDir.findFile(name) != null) return null
             return pickedDir.createDirectory(name)
         }
        return null
    }

    fun cloneFile(activity: FlutterFragmentActivity, baseUri: Uri, sourcePath: String, destinationPath: String): Boolean {
        val sourceUri = getDocumentUriForPath(activity, baseUri, sourcePath)
        val destinationUri = getDocumentUriForPath(activity, baseUri, destinationPath)
        Log.d(LOG_TAG, "$sourceUri [cloneFile]")
        Log.d(LOG_TAG, "$destinationUri [cloneFile]")

        val resolver: ContentResolver = activity.contentResolver
        try {
            val inputStream: InputStream = resolver.openInputStream(sourceUri) ?: return false
            val destDir = DocumentFile.fromTreeUri(activity, destinationUri)
            if (destDir == null || !destDir.isDirectory) return false
            // Use the source file’s name (or provide a parameter)
            val fileName = getFileName(activity, sourceUri) ?: "cloned_file"
            // If a file with the same name exists, delete it (or handle as desired)
            destDir.findFile(fileName)?.delete()
            val newFile = destDir.createFile("application/octet-stream", fileName) ?: return false
            val outputStream: OutputStream = resolver.openOutputStream(newFile.uri) ?: return false
            inputStream.copyTo(outputStream)
            inputStream.close()
            outputStream.close()
            // Attempt to update last modified metadata.
            updateLastModified(activity, sourceUri, newFile.uri)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    fun cloneDirectory(activity: FlutterFragmentActivity, baseUri: Uri, sourcePath: String, destinationPath: String): Boolean {
        val sourceUri = getDocumentUriForPath(activity, baseUri, sourcePath)
        val destinationUri = getDocumentUriForPath(activity, baseUri, destinationPath)

        val sourceDir = DocumentFile.fromTreeUri(activity, sourceUri)
        val destDir = DocumentFile.fromTreeUri(activity, destinationUri)
        if (sourceDir == null || destDir == null || !sourceDir.isDirectory || !destDir.isDirectory) return false

        try {
            sourceDir.listFiles().forEach { child ->
                if (child.isDirectory) {
                    // Create a corresponding directory in the destination
                    val newDir = destDir.createDirectory(child.name ?: "dir") ?: return@forEach
                    // Recursively clone the directory
                    cloneDirectory(activity, baseUri, child.uri.path!!, newDir.uri.path!!)
                } else if (child.isFile) {
                    // Clone the file
                    cloneFile(activity, baseUri, child.uri.path!!, destDir.uri.path!!)
                }
            }
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun getFileName(activity: FlutterFragmentActivity, uri: Uri): String? {
        return when (uri.scheme) {
            "content" -> {
                // Query the content resolver for display name.
                activity.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                        if (index != -1) cursor.getString(index) else null
                    } else null
                }
            }
            "file" -> {
                // Extract file name directly from the file path.
                File(uri.path ?: "").name
            }
            else -> null
        }
    }

    private fun updateLastModified(
        activity: FlutterFragmentActivity,
        sourceUri: Uri,
        destUri: Uri
    ) {
        val resolver = activity.contentResolver
        // First, get the source file’s last modified time.
        val sourceLastModified = resolver.query(
            sourceUri,
            arrayOf(DocumentsContract.Document.COLUMN_LAST_MODIFIED),
            null,
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getLong(0) else null
        } ?: return

        // Try to update via MediaStore (works best if the file is a media file, e.g. in DCIM)
        val destDoc = DocumentFile.fromSingleUri(activity, destUri)
        val fileName = destDoc?.name
        if (fileName != null) {
            // This sample assumes the file is an image.
            val mediaStoreUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            // Query for the file’s _ID using its display name.
            val projection = arrayOf(MediaStore.Images.Media._ID)
            val selection = "${MediaStore.Images.Media.DISPLAY_NAME}=?"
            val selectionArgs = arrayOf(fileName)
            val id = resolver.query(
                mediaStoreUri,
                projection,
                selection,
                selectionArgs,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getLong(0) else null
            }

            if (id != null) {
                val updateUri = ContentUris.withAppendedId(mediaStoreUri, id)
                val values = ContentValues().apply {
                    // MediaStore expects seconds.
                    put(MediaStore.Images.Media.DATE_MODIFIED, sourceLastModified / 1000)
                }
                val rows = resolver.update(updateUri, values, null, null)
                if (rows > 0) {
                    Log.d("MetadataUpdate", "MediaStore metadata updated successfully.")
                    return
                }
            }
        }

        // If MediaStore update isn’t applicable or fails, try updating via SAF.
        // Note: This often fails for SD card files due to platform restrictions.
        try {
            val values = ContentValues().apply {
                put(DocumentsContract.Document.COLUMN_LAST_MODIFIED, sourceLastModified)
            }
            val rows = resolver.update(destUri, values, null, null)
            if (rows > 0) {
                Log.d("MetadataUpdate", "SAF metadata updated successfully.")
            } else {
                Log.w("MetadataUpdate", "SAF metadata update returned 0 rows updated.")
            }
        } catch (e: UnsupportedOperationException) {
            Log.w("MetadataUpdate", "Update not supported for metadata update.", e)
        } catch (e: Exception) {
            Log.w("MetadataUpdate", "Could not update last modified time", e)
        }
    }

//    private fun updateLastModified0(activity: FlutterFragmentActivity, sourceUri: Uri, destUri: Uri) {
//        val resolver = activity.contentResolver
//        try {
//            // Query for the source file's last modified time.
//            val cursor =
//                resolver.query(
//                    sourceUri,
//                    arrayOf(DocumentsContract.Document.COLUMN_LAST_MODIFIED),
//                    null, null, null
//                )
//            if (cursor != null && cursor.moveToFirst()) {
//                val lastModified = cursor.getLong(0)
//                cursor.close()
//
//                // Update destination file metadata.
//                val values = ContentValues().apply {
//                    put(DocumentsContract.Document.COLUMN_LAST_MODIFIED, lastModified)
//                }
//                resolver.update(destUri, values, null, null)
//            } else {
//                cursor?.close()
//            }
//        } catch (e: UnsupportedOperationException) {
//            // Update not supported: log and ignore.
//            Log.w(LOG_TAG, "Update not supported for metadata update.", e)
//        } catch (e: Exception) {
//            // Log the exception and ignore metadata update failure.
//            e.printStackTrace()
//        }
//    }

    /**
     * Converts a full file-system path (e.g. "/storage/1618-1708/Download/New/")
     * into a corresponding Document URI using the given persisted SD card base URI.
     * If the path represents a normal file (e.g. internal storage like "/storage/emulated/0/files/abc.txt"),
     * it returns a file URI instead.
     *
     * @param baseUri The persisted SD card tree URI (e.g. "content://com.android.externalstorage.documents/tree/1618-1708%3A")
     * @param fullPath The full file system path (e.g. "/storage/1618-1708/Download/New/" or "/storage/emulated/0/files/abc.txt")
     * @return The SAF Document URI for the specified path, or a file URI for internal storage paths.
     * @throws Exception if the provided path does not match expected SD card or internal storage patterns.
     */
    private fun getDocumentUriForPath(context: Context, baseUri: Uri, fullPath: String): Uri {
        // For SD card paths:
        val baseDocumentId = DocumentsContract.getTreeDocumentId(baseUri)
        val storageId = baseDocumentId.removeSuffix(":")
        val expectedPrefix = "/storage/$storageId/"

        if (fullPath.startsWith(expectedPrefix)) {
            // Process as SD card storage:
            val relativePath = fullPath.substring(expectedPrefix.length).trim('/')
            val documentId = if (relativePath.isEmpty()) baseDocumentId else "$storageId:$relativePath"
            return DocumentsContract.buildDocumentUriUsingTree(baseUri, documentId)
        } else if (fullPath.startsWith("/storage/emulated/0/")) {
            // Process as a normal internal storage file path:
            val file = File(fullPath)
            return FileProvider.getUriForFile(context , "${context.packageName}.fileprovider", file)
            //return Uri.fromFile(file)
        } else {
            // If path doesn't match either expected pattern, throw an exception.
            throw Exception("The provided full path does not match the SD card or internal storage patterns")
        }
    }
}