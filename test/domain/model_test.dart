import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_files/domain/model.dart';

void main() {
  group('FileNode', () {
    test('sample data is not empty', () {
      expect(FileNode.seedLibrary, isNotEmpty);
    });

    test('matches humanised labels', () {
      for (final item in FileNode.seedLibrary) {
        expect(item.matches(item.displayName.toLowerCase()), isTrue);
      }
    });
  });
}