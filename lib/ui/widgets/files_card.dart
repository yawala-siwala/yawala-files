import 'package:flutter/material.dart';

import '../../domain/model.dart';

/// List row for a single FileNode.
class FileNodeCard extends StatelessWidget {
  const FileNodeCard({super.key, required this.item});

  final FileNode item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(item.isDirectory ? Icons.folder : Icons.insert_drive_file),
        title: Text(item.displayName),
        subtitle: Text(item.subtitle),
        trailing: Text(item.meta),
      ),
    );
  }
}