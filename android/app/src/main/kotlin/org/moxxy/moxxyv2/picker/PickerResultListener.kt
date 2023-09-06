package org.moxxy.moxxyv2.picker

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import org.moxxy.moxxyv2.plugin.AsyncRequestTracker
import org.moxxy.moxxyv2.plugin.PICK_FILES_REQUEST
import org.moxxy.moxxyv2.plugin.PICK_FILE_REQUEST
import org.moxxy.moxxyv2.plugin.PICK_FILE_WITH_DATA_REQUEST
import org.moxxy.moxxyv2.plugin.TAG
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream

class PickerResultListener(private val context: Context) : ActivityResultListener {
    /*
     * Attempt to deduce the filename for the URI @uri.
     * Based on https://stackoverflow.com/a/25005243
     */
    @SuppressLint("Range")
    private fun queryFileName(context: Context, uri: Uri): String {
        var result: String? = null
        if (uri.scheme == "content") {
            val cursor = context.contentResolver.query(uri, null, null, null, null)
            cursor.use { cursor ->
                if (cursor != null && cursor.moveToFirst()) {
                    result = cursor.getString(cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME))
                }
            }
        }

        return result ?: uri.path!!.split("/").last()
    }

    /*
     * Copy from the input stream @input to the output stream @output.
     * On Android >= 13 uses Android's own copy method. Below, reads the stream in 4096 byte
     * segments and write them back.
     *
     * Based on https://github.com/flutter/packages/blob/b8b84b2304f00a3f93ce585cc7a30e1235bde7a0/packages/image_picker/image_picker_android/android/src/main/java/io/flutter/plugins/imagepicker/FileUtils.java#L130
     */
    private fun copy(input: InputStream, output: OutputStream) {
        if (Build.VERSION.SDK_INT >= 33) {
            android.os.FileUtils.copy(input, output)
        } else {
            val buffer = ByteArray(4096)
            while (input.read(buffer).also {} != -1) {
                output.write(buffer)
            }
            output.flush()
        }
    }

    /*
     * Copy the content of the file @uri is pointing to into the cache directory for access from
     * within Flutter.
     *
     * Based on https://github.com/flutter/packages/blob/b8b84b2304f00a3f93ce585cc7a30e1235bde7a0/packages/image_picker/image_picker_android/android/src/main/java/io/flutter/plugins/imagepicker/FileUtils.java#L54C64-L54C64
     */
    private fun resolveContentUri(context: Context, uri: Uri): String? {
        try {
            val inputStream = context.contentResolver.openInputStream(uri)
            val cacheDir = File(context.cacheDir, "cache").apply {
                mkdir()
                deleteOnExit()
            }
            val cacheFile = File(cacheDir, queryFileName(context, uri))
            val outputStream = FileOutputStream(cacheFile)
            copy(inputStream!!, outputStream)

            return cacheFile.path
        } catch (ex: IOException) {
            Log.d(TAG, "IO exception while resolving URI $uri: ${ex.message}")
            return null;
        } catch (ex: SecurityException) {
            Log.d(TAG, "Security exception while resolving URI $uri: ${ex.message}")
            return null;
        }
    }

    private fun handlePickWithData(context: Context, resultCode: Int, data: Intent?, result: (Result<ByteArray?>) -> Unit) {
        // Handle not picking anything
        if (resultCode != Activity.RESULT_OK) {
            result(Result.success(null))
            return
        }

        val returnBuffer = mutableListOf<Byte>()
        val readBuffer = ByteArray(4096)
        try {
            val inputStream = context.contentResolver.openInputStream(data!!.data!!)!!
            while (inputStream.read(readBuffer).also {} != -1) {
                returnBuffer.addAll(readBuffer.asList())
            }
            inputStream.close()

            result(
                Result.success(returnBuffer.toByteArray())
            )
        } catch (ex: IOException) {
            Log.w(TAG, "IO exception while reading URI ${data!!.data}: ${ex.message}")
            result(Result.success(null))
        } catch (ex: SecurityException) {
            Log.w(TAG, "Security exception while reading URI ${data!!.data}: ${ex.message}")
            result(Result.success(null))
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.d(TAG, "Got result for $requestCode")
        if (requestCode != PICK_FILE_REQUEST && requestCode != PICK_FILES_REQUEST && requestCode != PICK_FILE_WITH_DATA_REQUEST) {
            return false
        }

        // Check if we have a request pending
        val result = AsyncRequestTracker.requestTracker.remove(requestCode)
        if (result == null) {
            Log.w(TAG, "Received result for $requestCode but we have no tracked request")
            return true
        }

        if (requestCode == PICK_FILE_WITH_DATA_REQUEST) {
            handlePickWithData(context, resultCode, data, result as (Result<ByteArray?>) -> Unit)
            return true
        }

        // No file(s) picked
        if (resultCode != Activity.RESULT_OK) {
            Log.d(TAG, "resultCode $resultCode != ${Activity.RESULT_OK}")
            result!!(Result.success(listOf<String>()))
            return true;
        }

        val pickedMultiple = requestCode == PICK_FILES_REQUEST
        val pickedFiles = mutableListOf<String>()
        if (pickedMultiple) {
            if (data!!.clipData != null) {
                Log.w(TAG, "Files shared: ${data!!.clipData!!.itemCount}")
                for (i in 0 until data!!.clipData!!.itemCount) {
                    val path = resolveContentUri(context, data!!.clipData!!.getItemAt(i).uri)
                    if (path != null) {
                        pickedFiles.add(path)
                    }
                }
            } else if (data!!.data != null) {
                // Handle the generic file picker with multiple=true returning only one file
                val path = resolveContentUri(context, data!!.data!!)
                if (path != null) {
                    pickedFiles.add(path)
                }
            } else {
                Log.w(TAG, "Multi-file intent has no clipData and data")
            }
        } else {
            if (data!!.data != null) {
                val path = resolveContentUri(context, data!!.data!!)
                if (path != null) {
                    pickedFiles.add(path)
                }
            } else {
                Log.w(TAG, "Single-file intent has no data")
            }
        }

        result!!(Result.success(pickedFiles))
        return true
    }
}