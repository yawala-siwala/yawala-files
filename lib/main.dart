import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'domain/service.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = FilesState(service: const FileSystemService());
  unawaited(state.reload());
  runApp(YawalaApp(state: state));
}