import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../domain/model.dart';
import '../../state/files_state.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/files_card.dart';
import '../widgets/files_toolbar.dart';
import '../widgets/storage_volume_bar.dart';

/// Responsive file explorer: path bar, volume selector, search/sort
/// controls and a folder/file item list. Native picker and permission
/// actions live in the app bar.
class FilesHomeScreen extends StatelessWidget {
  const FilesHomeScreen({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yawala Files'),
        actions: [
          IconButton(
            tooltip: 'Pick files (native dialog)',
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () => unawaited(state.pickFiles()),
          ),
          IconButton(
            tooltip: 'Pick a folder (native dialog)',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => unawaited(_pickDirectoryAndNavigate()),
          ),
          IconButton(
            tooltip: 'Request access to the current folder',
            icon: const Icon(Icons.folder_shared_outlined),
            onPressed: () => unawaited(state.requestAccess()),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items.toList(growable: false);
          return Column(
            children: [
              FilesToolbar(state: state),
              BreadcrumbBar(state: state),
              StorageVolumeBar(state: state),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('Nothing here - try another folder.'),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final node = items[index];
                          return FileNodeCard(
                            item: node,
                            selected:
                                state.selectedKeys.contains(state.keyOf(node)),
                            onTap: () => _onNodeTap(node),
                            onLongPress: () => state.toggleSelection(node),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return FloatingActionButton(
            tooltip: 'Go up one level',
            onPressed:
                state.canNavigateUp ? () => unawaited(state.navigateUp()) : null,
            child: const Icon(Icons.arrow_upward),
          );
        },
      ),
    );
  }

  void _onNodeTap(FileNode node) {
    if (node.isDirectory) {
      unawaited(state.enterDirectory(node));
    } else {
      state.toggleSelection(node);
    }
  }

  Future<void> _pickDirectoryAndNavigate() async {
    await state.pickDirectory();
  }
}
