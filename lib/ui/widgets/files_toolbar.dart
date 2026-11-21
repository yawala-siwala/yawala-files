import 'package:material_ui/material_ui.dart';

import '../../state/files_state.dart';

/// Search / filter bar with a sort-mode toggle, shown above the files list.
///
/// Wide layouts keep one row (field + sort + count); below 480 px the
/// controls stack so the search field keeps a usable width instead of being
/// squeezed by the chips.
class FilesToolbar extends StatelessWidget {
  const FilesToolbar({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dense = constraints.maxWidth < 480;
        if (dense) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'Search files and folders',
                  ),
                  onChanged: state.setFilter,
                ),
                ListenableBuilder(
                  listenable: state,
                  builder: (context, _) => Row(
                    children: [
                      _sortControl(state),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Chip(
                          label: Text('${state.items.length} files'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'Search files and folders',
                  ),
                  onChanged: state.setFilter,
                ),
              ),
              ListenableBuilder(
                listenable: state,
                builder: (context, _) => _sortControl(state),
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
      },
    );
  }

  /// Visible sort affordance (labelled chip instead of an icon-only button)
  /// so the active mode is readable without assistive tech.
  Widget _sortControl(FilesState state) {
    return ActionChip(
      avatar: const Icon(Icons.sort, size: 18),
      label: Text('Sort: ${_sortLabel(state.sortMode)}'),
      visualDensity: VisualDensity.compact,
      tooltip: 'Cycle sort mode',
      onPressed: state.cycleSortMode,
    );
  }

  String _sortLabel(FilesSortMode mode) {
    return switch (mode) {
      FilesSortMode.nameAsc => 'name',
      FilesSortMode.sizeDesc => 'size',
      FilesSortMode.modifiedDesc => 'modified',
    };
  }
}
