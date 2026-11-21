import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_files/domain/model.dart';
import 'package:yawala_files/domain/service.dart';
import 'package:yawala_files/native/platform_bindings.dart';
import 'package:yawala_files/state/files_state.dart';

/// Scriptable native binding for state tests.
class FakeFilesBinding implements FilesNativeBinding {
  List<String>? nextPickFiles;
  String? nextPickDirectory;
  List<StorageVolume> volumes = const <StorageVolume>[];
  DirectoryPermissionStatus nextPermission =
      DirectoryPermissionStatus.unsupported;

  @override
  Future<List<String>?> pickFiles({
    String? dialogTitle,
    bool multiple = false,
  }) async =>
      nextPickFiles;

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async =>
      nextPickDirectory;

  @override
  Future<List<StorageVolume>> listStorageVolumes() async => volumes;

  @override
  Future<DirectoryPermissionStatus> requestDirectoryAccess(String path) async =>
      nextPermission;
}

/// Binding that also implements the native directory-listing capability,
/// proving the service prefers platform data over the simulated tree.
class NativeListingFilesBinding implements FilesNativeBinding,
    DirectoryListingBinding {
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

  @override
  Future<List<FileNode>?> listDirectory(String path) async => <FileNode>[
        FileNode(
          name: 'from-native.txt',
          path: path,
          isDirectory: false,
          sizeBytes: 42,
          modified: DateTime(2026, 11, 19, 8, 0),
        ),
      ];
}

FilesState buildState({FakeFilesBinding? native}) {
  final binding = native ?? FakeFilesBinding();
  return FilesState(
    native: binding,
    service: FileSystemService(native: binding),
  );
}

void main() {
  group('FilesState navigation', () {
    test('load seeds the root listing and volume data', () async {
      final state = buildState();
      await state.load();

      expect(state.currentPath, '/');
      expect(state.isLoading, isFalse);
      expect(state.items, isNotEmpty);
      expect(state.canNavigateUp, isFalse);
    });

    test('breadcrumbs track the navigation path', () async {
      final state = buildState();
      await state.navigate('/home/yawala');

      final crumbs = state.breadcrumbs;
      expect(crumbs, hasLength(3));
      expect(crumbs[0].label, 'Root');
      expect(crumbs[0].path, '/');
      expect(crumbs[1].label, 'home');
      expect(crumbs[1].path, '/home');
      expect(crumbs[2].label, 'yawala');
      expect(crumbs[2].path, '/home/yawala');
      expect(state.canNavigateUp, isTrue);
    });

    test('navigateUp walks to the parent and stops at root', () async {
      final state = buildState();
      await state.navigate('/home/yawala');

      await state.navigateUp();
      expect(state.currentPath, '/home');

      await state.navigateUp();
      expect(state.currentPath, '/');
      expect(state.canNavigateUp, isFalse);

      await state.navigateUp(); // extra call is a safe no-op
      expect(state.currentPath, '/');
    });

    test('navigate normalises trailing slashes', () async {
      final state = buildState();
      await state.navigate('/home/yawala/');

      expect(state.currentPath, '/home/yawala');
    });

    test('enterDirectory descends into folders, ignores files', () async {
      final state = buildState();
      await state.load();

      final folder = state.items.firstWhere((n) => n.name == 'Documents');
      await state.enterDirectory(folder);
      expect(state.currentPath, '/Documents');

      await state.navigate('/');
      final file = state.items.firstWhere((n) => n.name == 'readme.md');
      await state.enterDirectory(file);
      expect(state.currentPath, '/');
    });
  });

  group('FilesState filtering and sorting', () {
    test('setFilter matches names case-insensitively', () async {
      final state = buildState();
      await state.load();

      state.setFilter('README');
      expect(state.items, hasLength(1));
      expect(state.items.single.name, 'readme.md');

      state.setFilter('');
      expect(state.items, hasLength(FileNode.seedLibrary.length));
    });

    test('folders always sort before files', () async {
      final state = buildState();
      await state.load();

      expect(state.items.take(3).every((n) => n.isDirectory), isTrue);
    });

    test('cycleSortMode walks name -> size -> modified -> name', () async {
      final state = buildState();
      await state.load();

      expect(state.sortMode, FilesSortMode.nameAsc);

      state.cycleSortMode(); // size
      expect(state.items.skip(3).first.name, 'holiday-photos.zip');

      state.cycleSortMode(); // modified
      expect(state.items.first.name, 'Documents'); // newest folder first

      state.cycleSortMode(); // back to name
      expect(state.sortMode, FilesSortMode.nameAsc);
    });
  });

  group('FilesState selection', () {
    test('toggleSelection and clearSelection manage the set', () async {
      final state = buildState();
      await state.load();

      final file = state.items.firstWhere((n) => n.name == 'readme.md');
      state.toggleSelection(file);
      expect(state.selectedKeys, contains(state.keyOf(file)));
      expect(state.selectedNodes, hasLength(1));

      state.toggleSelection(file);
      expect(state.selectedNodes, isEmpty);

      final folder = state.items.firstWhere((n) => n.name == 'Documents');
      state.toggleSelection(file);
      state.toggleSelection(folder);
      state.clearSelection();
      expect(state.selectedKeys, isEmpty);
    });
  });

  group('FilesState native bridge', () {
    test('pickFiles returns the native result', () async {
      final native = FakeFilesBinding()
        ..nextPickFiles = ['/home/yawala/a.md'];
      final state = buildState(native: native);

      expect(await state.pickFiles(), ['/home/yawala/a.md']);
    });

    test('pickDirectory navigates to the picked folder', () async {
      final native = FakeFilesBinding()..nextPickDirectory = '/home/yawala';
      final state = buildState(native: native);
      await state.load();

      final path = await state.pickDirectory();

      expect(path, '/home/yawala');
      expect(state.currentPath, '/home/yawala');
    });

    test('pickDirectory keeps the location when cancelled', () async {
      final state = buildState();
      await state.navigate('/home');

      expect(await state.pickDirectory(), isNull);
      expect(state.currentPath, '/home');
    });

    test('loadVolumes populates the selector and switching changes the listing',
        () async {
      final native = FakeFilesBinding()
        ..volumes = [
          const StorageVolume(
            name: 'SD card',
            rootPath: '/storage/sd',
            isRemovable: true,
            freeBytes: 1,
            totalBytes: 2,
          ),
        ];
      final state = buildState(native: native);
      await state.load();

      expect(state.hasVolumes, isTrue);
      expect(state.volumes.single.name, 'SD card');
      expect(state.items, hasLength(FileNode.seedLibrary.length));

      await state.selectVolume(state.volumes.single);
      expect(state.activeVolume?.name, 'SD card');
      expect(state.currentPath, '/storage/sd');
      // The volume root has its own simulated contents.
      expect(
        state.items.map((node) => node.name),
        containsAll(['Music', 'backups', 'offline-playlist.m3u']),
      );
    });

    test('requestAccess records the permission status', () async {
      final native = FakeFilesBinding()
        ..nextPermission = DirectoryPermissionStatus.granted;
      final state = buildState(native: native);

      final status = await state.requestAccess('/home');

      expect(status, DirectoryPermissionStatus.granted);
      expect(state.lastPermissionStatus, DirectoryPermissionStatus.granted);
    });
  });

  group('FilesState path-aware listing', () {
    test('entering a directory shows its own contents', () async {
      final state = buildState();
      await state.load();

      await state.enterDirectory(
        state.items.firstWhere((n) => n.name == 'Documents'),
      );

      expect(
        state.items.map((node) => node.name),
        containsAll(['Reports', 'invoices', 'lease-agreement.pdf']),
      );
      // Nested traversal reaches the reports folder.
      await state.enterDirectory(
        state.items.firstWhere((n) => n.name == 'Reports'),
      );
      expect(state.currentPath, '/Documents/Reports');
      expect(
        state.items.map((node) => node.name),
        containsAll(['q1-summary.pdf', 'q2-summary.pdf']),
      );

      // And up-navigation restores the parent listing.
      await state.navigateUp();
      expect(state.currentPath, '/Documents');
      expect(state.items.singleWhere((n) => n.name == 'meeting-notes.md'),
          isNotNull);
    });

    test('unknown directories list as empty instead of throwing', () async {
      final state = buildState();
      await state.navigate('/definitely/not/mapped');

      expect(state.currentPath, '/definitely/not/mapped');
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('a native listing capability takes precedence over the simulation',
        () async {
      final native = NativeListingFilesBinding();
      final state = FilesState(
        native: native,
        service: FileSystemService(native: native),
      );
      await state.load();

      expect(state.items, hasLength(1));
      expect(state.items.single.name, 'from-native.txt');
      expect(state.currentPath, '/');
    });
  });

  group('FilesState safe fallbacks', () {
    test('fallback binding keeps the explorer functional', () async {
      final state = FilesState(
        native: const FallbackFilesBinding(),
        service: const FileSystemService(),
      );
      await state.load();

      expect(await state.pickFiles(), isNull);
      expect(await state.pickDirectory(), isNull);
      expect(state.hasVolumes, isFalse);
      expect(
        await state.requestAccess('/'),
        DirectoryPermissionStatus.unsupported,
      );
      expect(state.lastPermissionStatus, DirectoryPermissionStatus.unsupported);
      // Core navigation still works without any native support.
      expect(state.items, isNotEmpty);
      expect(state.canNavigateUp, isFalse);
    });
  });
}
