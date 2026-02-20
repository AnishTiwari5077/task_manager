import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager/providers/task_provider.dart';

class FilterDialog extends ConsumerWidget {
  const FilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(statusFilterProvider);
    final priorityFilter = ref.watch(priorityFilterProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      title: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.sliders, // sliders = filter controls
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text('Filter Tasks', style: theme.textTheme.titleLarge),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status section ──
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons
                      .circleHalfStroke, // half-filled circle = status
                  size: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text('Status', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  context: context,
                  label: 'Pending',
                  icon: FontAwesomeIcons.hourglassHalf, // waiting
                  selected: statusFilter == 'pending',
                  onSelected: (s) =>
                      ref.read(statusFilterProvider.notifier).state = s
                      ? 'pending'
                      : null,
                ),
                _chip(
                  context: context,
                  label: 'In Progress',
                  icon: FontAwesomeIcons.bolt, // active
                  selected: statusFilter == 'in_progress',
                  onSelected: (s) =>
                      ref.read(statusFilterProvider.notifier).state = s
                      ? 'in_progress'
                      : null,
                ),
                _chip(
                  context: context,
                  label: 'Completed',
                  icon: FontAwesomeIcons.circleCheck, // done
                  selected: statusFilter == 'completed',
                  onSelected: (s) =>
                      ref.read(statusFilterProvider.notifier).state = s
                      ? 'completed'
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── Priority section ──
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.arrowUpWideShort, // sorted arrows = priority
                  size: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text('Priority', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  context: context,
                  label: 'High',
                  icon: FontAwesomeIcons.anglesUp, // ▲▲ urgent
                  selected: priorityFilter == 'high',
                  onSelected: (s) =>
                      ref.read(priorityFilterProvider.notifier).state = s
                      ? 'high'
                      : null,
                ),
                _chip(
                  context: context,
                  label: 'Medium',
                  icon: FontAwesomeIcons.equals, // = balanced
                  selected: priorityFilter == 'medium',
                  onSelected: (s) =>
                      ref.read(priorityFilterProvider.notifier).state = s
                      ? 'medium'
                      : null,
                ),
                _chip(
                  context: context,
                  label: 'Low',
                  icon: FontAwesomeIcons.anglesDown, // ▼▼ low urgency
                  selected: priorityFilter == 'low',
                  onSelected: (s) =>
                      ref.read(priorityFilterProvider.notifier).state = s
                      ? 'low'
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            ref.read(statusFilterProvider.notifier).state = null;
            ref.read(categoryFilterProvider.notifier).state = null;
            ref.read(priorityFilterProvider.notifier).state = null;
            Navigator.pop(context);
          },
          icon: const FaIcon(
            FontAwesomeIcons.filterCircleXmark, // filter with X = clear
            size: 14,
          ),
          label: const Text('Clear All'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const FaIcon(
            FontAwesomeIcons.check,
            size: 13,
          ), // checkmark = apply
          label: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _chip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      avatar: FaIcon(
        icon,
        size: 12,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: selected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: colorScheme.primary.withValues(alpha: .15),
      backgroundColor: colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: selected ? colorScheme.primary : colorScheme.outline,
      ),
      showCheckmark: false,
    );
  }
}
