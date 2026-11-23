package com.yawalasiwala.yawala_files

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.storage.StorageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Native host for Yawala Files: real storage volumes, real directory
/// enumeration and SAF document pickers over `com.yawalasiwala/files`.
class MainActivity : FlutterActivity() {
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listStorageVolumes" -> result.success(storageVolumes())
                    "listDirectory" -> result.success(
                        listDirectory(call.argument<String>("path") ?: "/")
                    )
                    "pickFiles" -> pickFiles(call.argument<Boolean>("multiple") == true, result)
                    "pickDirectory" -> pickDirectory(result)
                    "requestDirectoryAccess" -> result.success(
                        directoryAccessStatus(call.argument<String>("path") ?: "/")
                    )
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (pendingPickResult == null) {
            return
        }
        val result = pendingPickResult
        pendingPickResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            // User cancelled the dialog - null means "cancelled" to Dart.
            result?.success(null)
            return
        }
        when (requestCode) {
            REQUEST_PICK_FILES -> {
                val uris = mutableListOf<String>()
                data.data?.let { uris.add(it.toString()) }
                val clip = data.clipData
                if (clip != null) {
                    for (index in 0 until clip.itemCount) {
                        clip.getItemAt(index).uri?.let { uris.add(it.toString()) }
                    }
                }
                result?.success(if (uris.isEmpty()) null else uris)
            }
            REQUEST_PICK_DIRECTORY -> {
                val uri: Uri? = data.data
                result?.success(uri?.toString())
            }
        }
    }

    private fun hasMediaPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= 33) {
            listOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO,
                Manifest.permission.READ_MEDIA_AUDIO
            ).any {
                checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
            }
        } else {
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }
    }

    /// Real storage volumes from [StorageManager]: internal storage plus
    /// removable cards / drives, with live free-space figures.
    private fun storageVolumes(): List<Map<String, Any>> {
        val manager = getSystemService(Context.STORAGE_SERVICE) as? StorageManager
            ?: return emptyList()
        val volumes = mutableListOf<Map<String, Any>>()
        for (volume in manager.storageVolumes) {
            try {
                val directory = volume.directory
                val rootPath = directory?.absolutePath
                if (rootPath.isNullOrEmpty()) {
                    continue
                }
                volumes.add(
                    mapOf(
                        "name" to (volume.getDescription(this) ?: rootPath),
                        "rootPath" to rootPath,
                        "isRemovable" to volume.isRemovable,
                        "freeBytes" to (directory?.usableSpace ?: 0L),
                        "totalBytes" to (directory?.totalSpace ?: 0L)
                    )
                )
            } catch (_: Exception) {
                // Volume not mounted / inaccessible: skip it.
            }
        }
        return volumes
    }

    /// Real directory enumeration via java.io.File (FUSE view of shared
    /// storage). Returns `null` when the platform cannot enumerate - the
    /// Dart service then falls back to its simulated tree - and an empty
    /// list for real, empty directories.
    private fun listDirectory(path: String): List<Map<String, Any>>? {
        if (!hasMediaPermission()) {
            return null
        }
        return try {
            val directory = File(path)
            if (!directory.exists()) {
                return emptyList()
            }
            val entries = directory.listFiles() ?: return null
            entries.map { file ->
                mapOf(
                    "name" to file.name,
                    "path" to (file.parent ?: path),
                    "isDirectory" to file.isDirectory,
                    "sizeBytes" to file.length(),
                    "modified" to file.lastModified()
                )
            }
        } catch (error: Exception) {
            null
        }
    }

    private fun pickFiles(multiple: Boolean, result: MethodChannel.Result) {
        try {
            pendingPickResult = result
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multiple)
            }
            startActivityForResult(intent, REQUEST_PICK_FILES)
        } catch (error: Exception) {
            pendingPickResult = null
            result.success(null)
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        try {
            pendingPickResult = result
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            startActivityForResult(intent, REQUEST_PICK_DIRECTORY)
        } catch (error: Exception) {
            pendingPickResult = null
            result.success(null)
        }
    }

    /// POSIX-style readability probe for the requested path.
    private fun directoryAccessStatus(path: String): String {
        return try {
            val directory = File(path)
            if (directory.exists() && directory.canRead()) "granted" else "denied"
        } catch (error: Exception) {
            "denied"
        }
    }

    companion object {
        private const val CHANNEL = "com.yawalasiwala/files"
        private const val REQUEST_PICK_FILES = 4141
        private const val REQUEST_PICK_DIRECTORY = 4142
    }
}
