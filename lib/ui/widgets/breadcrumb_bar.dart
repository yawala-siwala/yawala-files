import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import '../../native/platform_bindings.dart';
import '../../state/files_state.dart';

/// Horizontal breadcrumb path bar with an optional permission-status chip.
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final crumbs = state.breadcrumbs;
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
                  itemCount: crumbs.length,
                  separatorBuilder: (_, __) =>
                      const Icon(Icons.chevron_right, size: 16),
                  itemBuilder: (context, index) {
                    final crumb = crumbs[index];
                    final isLast = index == crumbs.length - 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: YawalaSpacing.sm),
                      child: ActionChip(
                        label: Text(crumb.label),
                        visualDensity: VisualDensity.compact,
                        onPressed:
                            isLast ? null : () => unawaited(state.navigate(crumb.path)),
                      ),
                    );
                  },
                ),
              ),
              if (state.lastPermissionStatus != null)
                Padding(
                  padding: const EdgeInsets.only(right: YawalaSpacing.md),
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      _permissionIcon(state.lastPermissionStatus!),
                      size: 16,
                    ),
                    label: Text(
                      state.lastPermissionStatus!.name,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _permissionIcon(DirectoryPermissionStatus status) {
    return switch (status) {
      DirectoryPermissionStatus.granted => Icons.verified_user_outlined,
      DirectoryPermissionStatus.denied => Icons.gpp_bad_outlined,
      DirectoryPermissionStatus.unsupported => Icons.block_outlined,
    };
  }
}
