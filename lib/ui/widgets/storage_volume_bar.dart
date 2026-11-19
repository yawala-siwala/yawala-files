import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import '../../state/files_state.dart';

/// Horizontally scrollable storage-volume chips (drives, SD cards, roots).
/// Hidden entirely when the platform reports no volumes.
class StorageVolumeBar extends StatelessWidget {
  const StorageVolumeBar({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (!state.hasVolumes) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: YawalaSpacing.md,
                  ),
                  itemCount: state.volumes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: YawalaSpacing.xs),
                  itemBuilder: (context, index) {
                    final volume = state.volumes[index];
                    final isActive = state.activeVolume == volume;
                    return ChoiceChip(
                      label: Text(volume.name),
                      selected: isActive,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) =>
                          unawaited(state.selectVolume(volume)),
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Refresh volumes',
                icon: const Icon(Icons.refresh),
                onPressed: () => unawaited(state.loadVolumes()),
              ),
            ],
          ),
        );
      },
    );
  }
}
