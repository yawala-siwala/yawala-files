import 'package:material_ui/material_ui.dart';

import '../../domain/model.dart';

/// List row for a single FileNode. Distinguishes folders from files and
/// highlights the node when it is part of the current selection.
class FileNodeCard extends StatelessWidget {
  const FileNodeCard({
    super.key,
    required this.item,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final FileNode item;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          item.isDirectory ? Icons.folder : Icons.insert_drive_file,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(item.displayName),
        subtitle: Text(item.subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.meta),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        selected: selected,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
