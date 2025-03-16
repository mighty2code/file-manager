package com.example.file_manager

import android.content.ContentResolver
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import java.io.InputStream
import java.io.OutputStream

object SDCardUtils {
    fun createFile(activity: FlutterFragmentActivity, baseUri: Uri, destinationPath: String, name: String, mimeType: String): Uri? {
        val destinationUri = getDocumentUriForPath(baseUri, destinationPath)
        val pickedDir = DocumentFile.fromTreeUri(activity, destinationUri)
        if (pickedDir != null && pickedDir.isDirectory) {
            if (pickedDir.findFile(name) != null) return null
            val newFile = pickedDir.createFile(mimeType, name)
            return newFile?.uri
        }
        return null
    }

    fun createDirectory(activity: FlutterFragmentActivity, baseUri: Uri, destinationPath: String, name: String): DocumentFile? {
         val destinationUri = getDocumentUriForPath(baseUri, destinationPath)
         val pickedDir = DocumentFile.fromTreeUri(activity, destinationUri)
         if (pickedDir != null && pickedDir.isDirectory) {
             if (pickedDir.findFile(name) != null) return null
             return pickedDir.createDirectory(name)
         }
        return null
    }

    fun cloneFile(activity: FlutterFragmentActivity, baseUri: Uri, sourcePath: String, destinationPath: String): Boolean {
        val sourceUri = getDocumentUriForPath(baseUri, sourcePath)
        val destinationUri = getDocumentUriForPath(baseUri, destinationPath)

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
        val sourceUri = getDocumentUriForPath(baseUri, sourcePath)
        val destinationUri = getDocumentUriForPath(baseUri, destinationPath)

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
        // Query the content resolver to get the display name.
        val cursor = activity.contentResolver.query(uri, null, null, null, null)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
            cursor?.use {
                if (it.moveToFirst()) {
                    val index = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (index != -1) return it.getString(index)
                }
            }
        }
        return null
    }

    private fun updateLastModified(activity: FlutterFragmentActivity, sourceUri: Uri, destUri: Uri) {
        val resolver = activity.contentResolver
        try {
            // Query for the source file's last modified time.
            val cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                resolver.query(
                    sourceUri,
                    arrayOf(DocumentsContract.Document.COLUMN_LAST_MODIFIED),
                    null, null, null
                )
            } else {
                TODO("VERSION.SDK_INT < KITKAT")
            }
            if (cursor != null && cursor.moveToFirst()) {
                val lastModified = cursor.getLong(0)
                cursor.close()

                // Update destination file metadata.
                val values = ContentValues().apply {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        put(DocumentsContract.Document.COLUMN_LAST_MODIFIED, lastModified)
                    }
                }
                resolver.update(destUri, values, null, null)
            } else {
                cursor?.close()
            }
        } catch (e: Exception) {
            // Log the exception and ignore metadata update failure.
            e.printStackTrace()
        }
    }

    /**
    * Converts a full file-system path (e.g. "/storage/1618-1708/Download/New/")
    * into a corresponding Document URI using the given persisted SD card base URI.
    *
    * @param baseUri The persisted SD card tree URI (e.g. "content://com.android.externalstorage.documents/tree/1618-1708%3A")
    * @param fullPath The full file system path (e.g. "/storage/1618-1708/Download/New/")
    * @return The SAF Document URI for the specified path, or null if the fullPath does not match.
    */
    private fun getDocumentUriForPath(baseUri: Uri, fullPath: String): Uri {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            throw Exception("Exception : Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP [SDCardUtils.getDocumentUriForPath]")
        }
        // Get the base document ID (e.g. "1618-1708:")
        val baseDocumentId = DocumentsContract.getTreeDocumentId(baseUri)
        // Remove the trailing colon to extract the storage ID (e.g. "1618-1708")
        val storageId = baseDocumentId.removeSuffix(":")
        
        // The full path is expected to start with "/storage/{storageId}/"
        val expectedPrefix = "/storage/$storageId/"
        if (!fullPath.startsWith(expectedPrefix)) {
            // The provided full path does not match the SD card's storage ID.
            throw Exception("Exception : The provided full path does not match the SD card's storage ID [SDCardUtils.getDocumentUriForPath]")
        }
        
        // Get the relative path by removing the expected prefix and trimming any trailing slashes.
        val relativePath = fullPath.substring(expectedPrefix.length).trim('/')
        // Construct the document ID: if relativePath is empty, use the base; otherwise combine storageId and relativePath.
        val documentId = if (relativePath.isEmpty()) baseDocumentId else "$storageId:$relativePath"
        // Build and return the Document URI using the base URI and document ID.
        return DocumentsContract.buildDocumentUriUsingTree(baseUri, documentId)
    }
}