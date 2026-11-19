import 'package:flutter/foundation.dart';

import '../domain/model.dart';
import '../domain/service.dart';
import '../native/platform_bindings.dart';

/// How the item list is ordered. Folders always sort before files.
enum FilesSortMode { nameAsc, sizeDesc, modifiedDesc }

/// One clickable segment of the breadcrumb path bar.
class Breadcrumb {
  const Breadcrumb({required this.label, required this.path});

  final String label;
  final String path;
}

/// Reactive state machine for Yawala Files.
///
/// Owns directory navigation (breadcrumbs, up-navigation), item
/// filtering/sorting, node selection, storage volumes and the native
/// picker/permission actions. Every native call goes through
/// [FilesNativeBinding] (backed by core's `NativeChannelGateway`), so
/// unsupported platforms degrade to safe fallbacks instead of throwing.
class FilesState extends ChangeNotifier {
  FilesState({
    required FilesNativeBinding native,
    required FileSystemService service,
  })  : _native = native,
        _service = service;

  final FilesNativeBinding _native;
  final FileSystemService _service;

  List<FileNode> _items = const <FileNode>[];
  String _currentPath = '/';
  String _filter = '';
  FilesSortMode _sortMode = FilesSortMode.nameAsc;
  final Set<String> _selectedKeys = <String>{};
  List<StorageVolume> _volumes = const <StorageVolume>[];
  StorageVolume? _activeVolume;
  DirectoryPermissionStatus? _lastPermissionStatus;
  bool _isLoading = false;

  /// Full path of the directory currently being browsed.
  String get currentPath => _currentPath;

  /// Breadcrumb segments for the path bar (Root first).
  List<Breadcrumb> get breadcrumbs {
    final crumbs = <Breadcrumb>[const Breadcrumb(label: 'Root', path: '/')];
    var accumulated = '';
    for (final segment
        in _currentPath.split('/').where((segment) => segment.isNotEmpty)) {
      accumulated = '$accumulated/$segment';
      crumbs.add(Breadcrumb(label: segment, path: accumulated));
    }
    return crumbs;
  }

  /// Whether navigating up is possible (already at the root otherwise).
  bool get canNavigateUp => _currentPath != '/';

  /// Items matching the filter, folders first, then by the active sort.
  List<FileNode> get items {
    final filtered = _filter.isEmpty
        ? _items
        : _items.where((node) => node.matches(_filter)).toList(growable: false);
    final sorted = [...filtered]..sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return switch (_sortMode) {
          FilesSortMode.nameAsc =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          FilesSortMode.sizeDesc => b.sizeBytes.compareTo(a.sizeBytes),
          FilesSortMode.modifiedDesc => b.modified.compareTo(a.modified),
        };
      });
    return List.unmodifiable(sorted);
  }

  String get filter => _filter;
  FilesSortMode get sortMode => _sortMode;

  /// Keys of the currently selected nodes.
  Set<String> get selectedKeys => Set.unmodifiable(_selectedKeys);

  /// The currently selected nodes among the visible items.
  List<FileNode> get selectedNodes => [
        for (final node in _items)
          if (_selectedKeys.contains(keyOf(node))) node,
      ];

  /// Storage volumes reported by the platform (empty on fallbacks).
  List<StorageVolume> get volumes => List.unmodifiable(_volumes);
  StorageVolume? get activeVolume => _activeVolume;
  bool get hasVolumes => _volumes.isNotEmpty;

  DirectoryPermissionStatus? get lastPermissionStatus => _lastPermissionStatus;
  bool get isLoading => _isLoading;

  /// Stable identity for a node across reloads.
  String keyOf(FileNode node) =>
      node.path.endsWith('/') ? '${node.path}${node.name}' : '${node.path}/${node.name}';

  /// Loads volumes plus the initial directory listing.
  Future<void> load() async {
    await loadVolumes();
    await reload();
  }

  /// Refreshes the current directory listing.
  Future<void> reload() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _service.list();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigates to [path] and refreshes the listing.
  Future<void> navigate(String path) async {
    _currentPath = _normalize(path);
    notifyListeners();
    await reload();
  }

  /// Navigates into a directory node (no-op for files).
  Future<void> enterDirectory(FileNode node) async {
    if (!node.isDirectory) {
      return;
    }
    await navigate(keyOf(node));
  }

  /// Goes up one level; no-op at the file-system root.
  Future<void> navigateUp() async {
    if (!canNavigateUp) {
      return;
    }
    final parent = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
    await navigate(parent.isEmpty ? '/' : parent);
  }

  /// Updates the search filter applied to [items].
  void setFilter(String value) {
    _filter = value.trim().toLowerCase();
    notifyListeners();
  }

  /// Cycles the sort mode: name -> size -> modified -> name.
  void cycleSortMode() {
    _sortMode = switch (_sortMode) {
      FilesSortMode.nameAsc => FilesSortMode.sizeDesc,
      FilesSortMode.sizeDesc => FilesSortMode.modifiedDesc,
      FilesSortMode.modifiedDesc => FilesSortMode.nameAsc,
    };
    notifyListeners();
  }

  /// Toggles the selection of a node.
  void toggleSelection(FileNode node) {
    final key = keyOf(node);
    if (!_selectedKeys.remove(key)) {
      _selectedKeys.add(key);
    }
    notifyListeners();
  }

  /// Clears the current selection.
  void clearSelection() {
    _selectedKeys.clear();
    notifyListeners();
  }

  /// Refreshes the platform storage volumes.
  Future<void> loadVolumes() async {
    _volumes = await _native.listStorageVolumes();
    notifyListeners();
  }

  /// Selects a volume and browses to its root.
  Future<void> selectVolume(StorageVolume volume) async {
    _activeVolume = volume;
    await navigate(volume.rootPath);
  }

  /// Opens the native file picker; returns picked paths or null when
  /// cancelled/unsupported.
  Future<List<String>?> pickFiles() {
    return _native.pickFiles(dialogTitle: 'Pick files with Yawala Files');
  }

  /// Opens the native directory picker; navigates to the picked path when
  /// the user completes the dialog.
  Future<String?> pickDirectory() async {
    final path = await _native.pickDirectory(
      dialogTitle: 'Pick a folder with Yawala Files',
    );
    if (path != null) {
      await navigate(path);
    }
    return path;
  }

  /// Requests secure access to [path] (defaults to the current directory)
  /// and records the resulting status for the UI.
  Future<DirectoryPermissionStatus> requestAccess([String? path]) async {
    final status = await _native.requestDirectoryAccess(path ?? _currentPath);
    _lastPermissionStatus = status;
    notifyListeners();
    return status;
  }

  String _normalize(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return '/';
    }
    final withoutTrailing =
        trimmed.length > 1 && trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    return withoutTrailing.isEmpty ? '/' : withoutTrailing;
  }
}
