package com.yawalasiwala.yawala_files

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Yawala Files - Android runner bootstrap.
 *
 * Registers the `com.yawalasiwala/files` method channel so the Dart layer can
 * drive native pickers (SAF ACTION_OPEN_DOCUMENT / ACTION_OPEN_DOCUMENT_TREE),
 * storage-volume enumeration (StorageManager) and secure directory
 * permissions (SAF persisted grants). Values below are safe-fallback stubs
 * until the real SAF integration lands.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFiles", "pickDirectory" -> result.success(null)
                    "listStorageVolumes" -> result.success(
                        listOf(
                            mapOf(
                                "name" to "Internal storage",
                                "rootPath" to "/storage/emulated/0",
                                "isRemovable" to false,
                                "freeBytes" to 0L,
                                "totalBytes" to 0L,
                            ),
                        ),
                    )
                    "requestDirectoryAccess" -> result.success("unsupported")
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val CHANNEL = "com.yawalasiwala/files"
    }
}
