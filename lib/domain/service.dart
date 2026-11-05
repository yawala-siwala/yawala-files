import 'model.dart';

/// Data access for the file-system browser.
///
/// The boilerplate surfaces [FileNode.seedLibrary]; the real implementation
/// goes through native directory APIs via `platform_bindings.dart`.
class FileSystemService {
  const FileSystemService();

  Future<List<FileNode>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // TODO(mvp): delegate to a platform channel that lists the real contents
    // of the current directory on every supported OS.
    return List.unmodifiable(FileNode.seedLibrary);
  }
}