import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import 'state/app_state.dart';
import 'ui/screens/home_screen.dart';

/// Root widget for Yawala Files.
class YawalaApp extends StatelessWidget {
  const YawalaApp({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yawala Files',
      debugShowCheckedModeBanner: false,
      theme: buildYawalaTheme(seedColor: YawalaColors.files),
      darkTheme: buildYawalaTheme(
        brightness: Brightness.dark,
        seedColor: YawalaColors.files,
      ),
      themeMode: ThemeMode.system,
      home: FilesHomeScreen(state: state),
    );
  }
}
