import 'package:flutter/material.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00696C),
        ),
      ),
      home: FilesHomeScreen(state: state),
    );
  }
}