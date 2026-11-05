import 'package:flutter/foundation.dart';

import 'package:yawala_core/yawala_core.dart';

/// A file or folder node shown in the Yawala Files browser.
@immutable
class FileNode {
  const FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.sizeBytes,
    required this.modified,
  });

  /// Sample directory contents used by the boilerplate service until the
  /// native directory APIs are wired up through `platform_bindings.dart`.
  static final List<FileNode> seedLibrary = [
    FileNode(
      name: 'Documents',
      path: '/',
      isDirectory: true,
      sizeBytes: 4096,
      modified: DateTime(2026, 11, 4, 9, 30),
    ),
    FileNode(
      name: 'Pictures',
      path: '/',
      isDirectory: true,
      sizeBytes: 4096,
      modified: DateTime(2026, 11, 3, 18, 5),
    ),
    FileNode(
      name: 'Projects',
      path: '/',
      isDirectory: true,
      sizeBytes: 4096,
      modified: DateTime(2026, 11, 2, 8, 0),
    ),
    FileNode(
      name: 'readme.md',
      path: '/',
      isDirectory: false,
      sizeBytes: 2146,
      modified: DateTime(2026, 11, 1, 21, 45),
    ),
    FileNode(
      name: 'holiday-photos.zip',
      path: '/',
      isDirectory: false,
      sizeBytes: 48318320,
      modified: DateTime(2026, 10, 30, 12, 0),
    ),
    FileNode(
      name: 'budget-2026.csv',
      path: '/',
      isDirectory: false,
      sizeBytes: 73110,
      modified: DateTime(2026, 10, 28, 16, 20),
    ),
    FileNode(
      name: 'teardown-notes.txt',
      path: '/',
      isDirectory: false,
      sizeBytes: 5120,
      modified: DateTime(2026, 10, 25, 7, 10),
    ),
  ];

  final String name;
  final String path;
  final bool isDirectory;
  final int sizeBytes;
  final DateTime modified;

  String get displayName => name;
  String get subtitle => path;
  String get meta => isDirectory ? 'folder' : formatBytes(sizeBytes);

  bool matches(String query) => displayName.toLowerCase().contains(query);

  @override
  String toString() => 'FileNode($path$name)';
}