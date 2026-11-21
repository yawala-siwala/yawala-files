import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_files/domain/service.dart';
import 'package:yawala_files/native/platform_bindings.dart';
import 'package:yawala_files/state/files_state.dart';
import 'package:yawala_files/ui/screens/home_screen.dart';

/// Scriptable native binding for widget tests.
class FakeFilesBinding implements FilesNativeBinding {
  List<StorageVolume> volumes = const <StorageVolume>[];

  @override
  Future<List<String>?> pickFiles({
    String? dialogTitle,
    bool multiple = false,
  }) async =>
      null;

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async => null;

  @override
  Future<List<StorageVolume>> listStorageVolumes() async => volumes;

  @override
  Future<DirectoryPermissionStatus> requestDirectoryAccess(String path) async =>
      DirectoryPermissionStatus.unsupported;
}

FilesState buildState() {
  final native = FakeFilesBinding();
  return FilesState(
    native: native,
    service: FileSystemService(native: native),
  );
}

/// Titles of the rendered file cards, in visible order.
List<String> renderedTitles(WidgetTester tester) {
  return [
    for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
      ((tile.title as Text?)?.data ?? ''),
  ];
}

void main() {
  testWidgets('explorer journey: load, filter, sort, navigate, select',
      (tester) async {
    final state = buildState();
    // Loading awaits a Future.delayed inside the service, which runs on the
    // test's fake clock - fire it off and let pumpAndSettle advance time
    // instead of deadlocking on a direct await.
    unawaited(state.load());

    await tester.pumpWidget(MaterialApp(home: FilesHomeScreen(state: state)));
    await tester.pumpAndSettle();

    // Root listing renders folders before files.
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('readme.md'), findsOneWidget);
    final rootTitles = renderedTitles(tester);
    expect(rootTilesAreFoldersFirst(rootTitles), isTrue);

    // Filtering narrows the visible list.
    await tester.enterText(find.byType(TextField), 'readme');
    await tester.pump();
    expect(find.text('readme.md'), findsOneWidget);
    expect(find.text('Documents'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    // Sorting by size puts the largest file first among the files.
    await tester.tap(find.text('Sort: name'));
    await tester.pumpAndSettle();
    expect(state.sortMode, FilesSortMode.sizeDesc);
    final sizeSorted = renderedTitles(tester);
    expect(sizeSorted[3], 'holiday-photos.zip');

    // Tapping a folder navigates and swaps the listing.
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(state.currentPath, '/Documents');
    expect(find.text('meeting-notes.md'), findsOneWidget);

    // The FAB goes back up one level.
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();
    expect(state.currentPath, '/');
    expect(find.text('Documents'), findsOneWidget);

    // Long-press toggles the selection checkmark.
    await tester.longPress(find.text('readme.md'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(state.selectedNodes.single.name, 'readme.md');
  });

  testWidgets('volume switcher swaps the listing and marks the active volume',
      (tester) async {
    final native = FakeFilesBinding()
      ..volumes = const [
        StorageVolume(
          name: 'SD card',
          rootPath: '/storage/sd',
          isRemovable: true,
          freeBytes: 1,
          totalBytes: 2,
        ),
      ];
    final state = FilesState(
      native: native,
      service: FileSystemService(native: native),
    );
    // Same fake-clock rule as the journey test above: no direct await on
    // the delayed load inside a testWidgets body.
    unawaited(state.load());

    await tester.pumpWidget(MaterialApp(home: FilesHomeScreen(state: state)));
    await tester.pumpAndSettle();

    expect(find.text('SD card'), findsOneWidget);
    await tester.tap(find.text('SD card'));
    await tester.pumpAndSettle();

    expect(state.currentPath, '/storage/sd');
    expect(find.text('offline-playlist.m3u'), findsOneWidget);
  });
}

bool rootTilesAreFoldersFirst(List<String> titles) {
  final folderNames = {'Documents', 'Pictures', 'Projects'};
  var seenFile = false;
  for (final title in titles) {
    if (folderNames.contains(title)) {
      if (seenFile) {
        return false;
      }
    } else {
      seenFile = true;
    }
  }
  return true;
}
