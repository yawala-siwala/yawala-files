import 'package:flutter/services.dart';

import 'package:yawala_core/yawala_core.dart';

import '../domain/model.dart';

/// Native contract for Yawala Files.
///
/// Channel: `com.yawalasiwala/files`
///
/// | Method | Purpose | Android | iOS | Desktop |
/// | --- | --- | --- | --- | --- |
/// | `pickFiles` | Native file picker dialog | SAF ACTION_OPEN_DOCUMENT | UIDocumentPicker | GTK portal / NSOpenPanel / IFileOpenDialog |
/// | `pickDirectory` | Native directory picker | SAF ACTION_OPEN_DOCUMENT_TREE | UIDirectoryPicker | same portals |
/// | `listStorageVolumes` | Enumerate storage volumes | StorageManager volumes | available containers | mount points / drive roots |
/// | `requestDirectoryAccess` | Secure directory permissions | SAF persisted permission grant | security-scoped bookmark | POSIX permissions check |
/// | `listDirectory` | Enumerate a directory's contents | DocumentFile list / File.list | NSDirectoryEnumerator | g_dir_read_name / Directory.Enumerate |
///
/// Every call goes through [NativeChannelGateway] and therefore resolves to
/// safe fallbacks instead of throwing on platforms without a handler.
const MethodChannel filesChannel = MethodChannel('com.yawalasiwala/files');

/// One storage volume (drive root) reported by the platform.
class StorageVolume {
  const StorageVolume({
    required this.name,
    required this.rootPath,
    required this.isRemovable,
    required this.freeBytes,
    required this.totalBytes,
  });

  factory StorageVolume.fromMap(Map<Object?, Object?>? map) {
    return StorageVolume(
      name: (map?['name'] as String?) ?? 'unknown',
      rootPath: (map?['rootPath'] as String?) ?? '/',
      isRemovable: (map?['isRemovable'] as bool?) ?? false,
      freeBytes: ((map?['freeBytes'] as num?) ?? 0).toInt(),
      totalBytes: ((map?['totalBytes'] as num?) ?? 0).toInt(),
    );
  }

  final String name;
  final String rootPath;
  final bool isRemovable;
  final int freeBytes;
  final int totalBytes;
}

/// Outcome of a directory-permission request (SAF grant on Android, POSIX
/// permission check on Linux/macOS, security-scoped bookmark on iOS).
enum DirectoryPermissionStatus { granted, denied, unsupported }

/// Parses the wire representation sent by native hosts.
DirectoryPermissionStatus directoryPermissionStatusFrom(String? value) {
  return switch (value) {
    'granted' => DirectoryPermissionStatus.granted,
    'denied' => DirectoryPermissionStatus.denied,
    _ => DirectoryPermissionStatus.unsupported,
  };
}

/// Contract every platform host implements for Yawala Files.
abstract interface class FilesNativeBinding {
  /// Opens the native file picker; returns picked paths or `null` when the
  /// user cancelled the dialog.
  Future<List<String>?> pickFiles({
    String? dialogTitle,
    bool multiple = false,
  });

  /// Opens the native directory picker; returns the picked path or `null`
  /// when the user cancelled the dialog.
  Future<String?> pickDirectory({String? dialogTitle});

  /// Enumerates the storage volumes visible to the app.
  Future<List<StorageVolume>> listStorageVolumes();

  /// Requests read access to [path] through the platform's secure
  /// permission mechanism (SAF on Android, POSIX check on desktop).
  Future<DirectoryPermissionStatus> requestDirectoryAccess(String path);
}

/// Optional capability for bindings that can enumerate directory contents
/// natively.
///
/// The domain service detects this capability with an `is` check, so
/// bindings that only implement [FilesNativeBinding] keep working unchanged:
/// when the capability is absent - or when the platform yields no data -
/// the service falls back to its simulated directory tree.
abstract interface class DirectoryListingBinding {
  /// Lists the contents of [path]. Returns `null` when the platform cannot
  /// enumerate this path (no handler, unknown directory, IO failure) so the
  /// caller can fall back. Entries are decoded through [FileNode.fromMap].
  Future<List<FileNode>?> listDirectory(String path);
}

/// Real implementation that speaks to the host platform over
/// [filesChannel], mapping failures to safe fallbacks.
class MethodChannelFilesBinding
    implements FilesNativeBinding, DirectoryListingBinding {
  MethodChannelFilesBinding({MethodChannel? channel})
      : _gateway = NativeChannelGateway(
          channel: channel ?? filesChannel,
          context: 'files.native',
        );

  final NativeChannelGateway _gateway;

  @override
  Future<List<String>?> pickFiles({
    String? dialogTitle,
    bool multiple = false,
  }) async {
    final result = await _gateway.invoke<List<Object?>>('pickFiles',
        <String, Object?>{'title': dialogTitle, 'multiple': multiple});
    return result.fold(
      ok: (paths) => paths?.whereType<String>().toList(growable: false),
      err: (_, __) => null,
    );
  }

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async {
    final result = await _gateway
        .invoke<String>('pickDirectory', <String, Object?>{
      'title': dialogTitle,
    });
    return result.fold(
      ok: (path) => path,
      err: (_, __) => null,
    );
  }

  @override
  Future<List<StorageVolume>> listStorageVolumes() async {
    final result = await _gateway.invoke<List<Object?>>('listStorageVolumes');
    return result.fold(
      ok: (volumes) => <StorageVolume>[
        for (final volume in volumes ?? const <Object?>[])
          StorageVolume.fromMap(volume as Map<Object?, Object?>),
      ],
      err: (_, __) => const <StorageVolume>[],
    );
  }

  @override
  Future<DirectoryPermissionStatus> requestDirectoryAccess(String path) async {
    final result = await _gateway
        .invoke<String>('requestDirectoryAccess', <String, Object?>{
      'path': path,
    });
    return directoryPermissionStatusFrom(result.valueOrNull);
  }

  @override
  Future<List<FileNode>?> listDirectory(String path) async {
    final result = await _gateway.invoke<List<Object?>>(
      'listDirectory',
      <String, Object?>{'path': path},
    );
    return result.fold(
      ok: (nodes) => nodes == null
          ? null
          : <FileNode>[
              for (final node in nodes)
                FileNode.fromMap(node as Map<Object?, Object?>),
            ],
      err: (_, __) => null,
    );
  }
}

/// No-op implementation for tests and platforms without any native host.
class FallbackFilesBinding implements FilesNativeBinding {
  const FallbackFilesBinding();

  @override
  Future<List<String>?> pickFiles({
    String? dialogTitle,
    bool multiple = false,
  }) async =>
      null;

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async => null;

  @override
  Future<List<StorageVolume>> listStorageVolumes() async =>
      const <StorageVolume>[];

  @override
  Future<DirectoryPermissionStatus> requestDirectoryAccess(String path) async =>
      DirectoryPermissionStatus.unsupported;
}

/// Boots the platform binding for the current OS.
FilesNativeBinding bootFilesNative() => MethodChannelFilesBinding();
