import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../widgets/files_card.dart';
import '../widgets/files_toolbar.dart';

/// Main screen of Yawala Files: toolbar, files list and primary action.
class FilesHomeScreen extends StatelessWidget {
  const FilesHomeScreen({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yawala Files')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items.toList(growable: false);
          if (items.isEmpty) {
            return const Center(
              child: Text('Nothing found - try a different search.'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => FileNodeCard(item: items[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Reload folder',
        onPressed: state.reload,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}