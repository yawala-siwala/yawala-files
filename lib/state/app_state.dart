import 'package:flutter/foundation.dart';

import '../domain/model.dart';
import '../domain/service.dart';

/// Owns the observable state of Yawala Files: filtered files, loading
/// flag and app-scoped runtime flags. Widgets rebuild via notifyListeners.
class FilesState extends ChangeNotifier {
  FilesState({required FileSystemService service}) : _service = service;

  final FileSystemService _service;
  String _filter = '';
  bool _loading = false;
  List<FileNode> _items = const [];

  /// Root path of the browsing session; desktop targets may show drive roots.
  String currentPath = '/';


  Iterable<FileNode> get items => _filter.isEmpty
      ? _items
      : _items.where((item) => item.matches(_filter.toLowerCase()));

  bool get isLoading => _loading;

  void setFilter(String value) {
    _filter = value.trim().toLowerCase();
    notifyListeners();
  }

  /// Browses into [path]. TODO(mvp): resolve "..", breadcrumbs and platform
  /// drive roots through the platform binding, then reload the listing.
  void enterDirectory(String path) {
    currentPath = path;
    notifyListeners();
  }

  Future<void> reload() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _service.list();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}