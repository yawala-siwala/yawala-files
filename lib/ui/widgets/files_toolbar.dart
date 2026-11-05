import 'package:flutter/material.dart';

import '../../state/app_state.dart';

/// Search / filter bar shown above the files list.
class FilesToolbar extends StatelessWidget {
  const FilesToolbar({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: 'Search files and folders',
              ),
              onChanged: state.setFilter,
            ),
          ),
          ListenableBuilder(
            listenable: state,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Chip(label: Text('${state.items.length} files')),
            ),
          ),
        ],
      ),
    );
  }
}