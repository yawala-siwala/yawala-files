import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_files/native/platform_bindings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final binding = MethodChannelFilesBinding();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(filesChannel, null);
  });

  group('MethodChannelFilesBinding with a live native handler', () {
    test('pickFiles returns the picked paths', () async {
      messenger.setMockMethodCallHandler(filesChannel, (call) async {
        expect(call.method, 'pickFiles');
        expect((call.arguments as Map<Object?, Object?>)['multiple'], true);
        return ['/home/yawala/a.md', '/home/yawala/b.md'];
      });

      final paths =
          await binding.pickFiles(dialogTitle: 'Import', multiple: true);

      expect(paths, ['/home/yawala/a.md', '/home/yawala/b.md']);
    });

    test('pickDirectory returns the picked path', () async {
      messenger.setMockMethodCallHandler(filesChannel, (call) async {
        return '/home/yawala/Projects';
      });

      expect(
        await binding.pickDirectory(dialogTitle: 'Open folder'),
        '/home/yawala/Projects',
      );
    });

    test('listStorageVolumes maps every volume', () async {
      messenger.setMockMethodCallHandler(filesChannel, (call) async {
        return [
          {
            'name': 'Internal',
            'rootPath': '/storage/emulated/0',
            'isRemovable': false,
            'freeBytes': 1024,
            'totalBytes': 2048,
          },
        ];
      });

      final volumes = await binding.listStorageVolumes();

      expect(volumes, hasLength(1));
      expect(volumes.single.name, 'Internal');
      expect(volumes.single.rootPath, '/storage/emulated/0');
      expect(volumes.single.isRemovable, isFalse);
      expect(volumes.single.freeBytes, 1024);
      expect(volumes.single.totalBytes, 2048);
    });

    test('requestDirectoryAccess maps granted statuses', () async {
      messenger.setMockMethodCallHandler(filesChannel, (call) async {
        expect(call.method, 'requestDirectoryAccess');
        return 'granted';
      });

      expect(
        await binding.requestDirectoryAccess('/home/yawala/Projects'),
        DirectoryPermissionStatus.granted,
      );
    });
  });

  group('native errors degrade to fallbacks', () {
    test('pickers, volumes and permissions survive PlatformException',
        () async {
      messenger.setMockMethodCallHandler(filesChannel, (call) async {
        throw PlatformException(code: 'E_SAF', message: 'provider busy');
      });

      expect(await binding.pickFiles(), isNull);
      expect(await binding.pickDirectory(), isNull);
      expect(await binding.listStorageVolumes(), isEmpty);
      expect(
        await binding.requestDirectoryAccess('/home/yawala'),
        DirectoryPermissionStatus.unsupported,
      );
    });
  });

  group('channel invocation safety (no native handler registered)', () {
    test('pickers degrade to null (treated as cancelled)', () async {
      expect(await binding.pickFiles(), isNull);
      expect(await binding.pickDirectory(), isNull);
    });

    test('volumes and permissions degrade to safe defaults', () async {
      expect(await binding.listStorageVolumes(), isEmpty);
      expect(
        await binding.requestDirectoryAccess('/anywhere'),
        DirectoryPermissionStatus.unsupported,
      );
    });
  });

  group('FallbackFilesBinding', () {
    const fallback = FallbackFilesBinding();

    test('mirrors the safe fallbacks', () async {
      expect(await fallback.pickFiles(), isNull);
      expect(await fallback.pickDirectory(), isNull);
      expect(await fallback.listStorageVolumes(), isEmpty);
      expect(
        await fallback.requestDirectoryAccess('/anywhere'),
        DirectoryPermissionStatus.unsupported,
      );
    });
  });
}
