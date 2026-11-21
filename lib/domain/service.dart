import 'package:yawala_core/yawala_core.dart';

import '../native/platform_bindings.dart';
import 'model.dart';

/// Data access for the file-system browser.
///
/// Resolution order for [list]:
/// 1. a native directory listing, when the injected binding implements
///    [DirectoryListingBinding] and the platform returns data for [path];
/// 2. a deterministic simulated directory tree otherwise, so navigation,
///    filtering and sorting stay fully testable and the explorer remains
///    functional on platforms without a native handler.
class FileSystemService {
  const FileSystemService({FilesNativeBinding? native}) : _native = native;

  final FilesNativeBinding? _native;

  /// Lists the contents of [path], trying the native capability first and
  /// falling back to the simulated tree when it is unavailable.
  Future<List<FileNode>> list(String path) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final native = _native;
    if (native is DirectoryListingBinding) {
      final listed = await native.listDirectory(path);
      if (listed != null) {
        YawalaLog.debug('native listing for $path (${listed.length} entries)');
        return List.unmodifiable(listed);
      }
    }
    return _simulatedListing(path);
  }

  List<FileNode> _simulatedListing(String path) {
    final directory = _simulatedTree[path];
    if (directory == null) {
      YawalaLog.debug('no simulated entries for $path; showing empty folder');
      return const <FileNode>[];
    }
    return List.unmodifiable(directory);
  }
}

/// Deterministic sample file system used when the platform cannot enumerate
/// directories. Keys are directory paths exactly as [FilesState.keyOf]
/// builds them. Values are non-const because [FileNode] carries [DateTime]s.
final Map<String, List<FileNode>> _simulatedTree = _buildSimulatedTree();

Map<String, List<FileNode>> _buildSimulatedTree() {
  FileNode node(
    String name,
    String path,
    bool isDirectory,
    int sizeBytes,
    DateTime modified,
  ) =>
      FileNode(
        name: name,
        path: path,
        isDirectory: isDirectory,
        sizeBytes: sizeBytes,
        modified: modified,
      );

  return <String, List<FileNode>>{
    '/': FileNode.seedLibrary,
    '/Documents': <FileNode>[
      node('Reports', '/Documents', true, 4096, DateTime(2026, 11, 10, 8, 0)),
      node('invoices', '/Documents', true, 4096, DateTime(2026, 11, 6, 14, 25)),
      node(
        'lease-agreement.pdf',
        '/Documents',
        false,
        182300,
        DateTime(2026, 11, 2, 10, 12),
      ),
      node(
        'meeting-notes.md',
        '/Documents',
        false,
        9400,
        DateTime(2026, 11, 12, 16, 45),
      ),
    ],
    '/Documents/Reports': <FileNode>[
      node(
        'q1-summary.pdf',
        '/Documents/Reports',
        false,
        240000,
        DateTime(2026, 5, 2, 9, 0),
      ),
      node(
        'q2-summary.pdf',
        '/Documents/Reports',
        false,
        255000,
        DateTime(2026, 8, 3, 9, 30),
      ),
    ],
    '/Pictures': <FileNode>[
      node('Camera', '/Pictures', true, 4096, DateTime(2026, 11, 9, 20, 0)),
      node(
        'Screenshots',
        '/Pictures',
        true,
        4096,
        DateTime(2026, 11, 11, 7, 15),
      ),
      node(
        'sunset.jpg',
        '/Pictures',
        false,
        2411000,
        DateTime(2026, 10, 31, 18, 40),
      ),
      node(
        'mountains.jpg',
        '/Pictures',
        false,
        3180000,
        DateTime(2026, 10, 30, 11, 5),
      ),
    ],
    '/Projects': <FileNode>[
      node('yawala-core', '/Projects', true, 4096, DateTime(2026, 11, 18, 6, 0)),
      node(
        'yawala-music',
        '/Projects',
        true,
        4096,
        DateTime(2026, 11, 17, 22, 10),
      ),
      node(
        'readme.md',
        '/Projects',
        false,
        3100,
        DateTime(2026, 11, 1, 12, 0),
      ),
    ],
    '/Projects/yawala-core': <FileNode>[
      node(
        'pubspec.yaml',
        '/Projects/yawala-core',
        false,
        860,
        DateTime(2026, 11, 15, 13, 5),
      ),
      node(
        'theme.dart',
        '/Projects/yawala-core',
        false,
        11400,
        DateTime(2026, 11, 14, 18, 20),
      ),
    ],
    '/storage/sd': <FileNode>[
      node('Music', '/storage/sd', true, 4096, DateTime(2026, 11, 8, 9, 0)),
      node('backups', '/storage/sd', true, 4096, DateTime(2026, 11, 5, 3, 30)),
      node(
        'offline-playlist.m3u',
        '/storage/sd',
        false,
        2400,
        DateTime(2026, 11, 7, 19, 55),
      ),
    ],
  };
}
