import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'domain/service.dart';
import 'native/platform_bindings.dart';
import 'state/files_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final native = bootFilesNative();
  final state = FilesState(
    native: native,
    service: FileSystemService(native: native),
  );
  unawaited(state.load());
  runApp(YawalaApp(state: state));
}
