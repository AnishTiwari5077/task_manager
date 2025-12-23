import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      title: Text('Filter Tasks', style: theme.textTheme.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _chip(
                  context: context,
                  label: 'Pending',
                  selected: statusFilter == 'pending',
                  onSelected: (selected) {
                    ref.read(statusFilterProvider.notifier).state = selected
                        ? 'pending'
                        : null;
                  },
                ),
                _chip(
                  context: context,
                  label: 'In Progress',
                  selected: statusFilter == 'in_progress',
                  onSelected: (selected) {
                    ref.read(statusFilterProvider.notifier).state = selected
                        ? 'in_progress'
                        : null;
                  },
                ),
                _chip(
                  context: context,
                  label: 'Completed',
                  selected: statusFilter == 'completed',
                  onSelected: (selected) {
                    ref.read(statusFilterProvider.notifier).state = selected
                        ? 'completed'
                        : null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Priority', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _chip(
                  context: context,
                  label: 'High',
                  selected: priorityFilter == 'high',
                  onSelected: (selected) {
                    ref.read(priorityFilterProvider.notifier).state = selected
                        ? 'high'
                        : null;
                  },
                ),
                _chip(
                  context: context,
                  label: 'Medium',
                  selected: priorityFilter == 'medium',
                  onSelected: (selected) {
                    ref.read(priorityFilterProvider.notifier).state = selected
                        ? 'medium'
                        : null;
                  },
                ),
                _chip(
                  context: context,
                  label: 'Low',
                  selected: priorityFilter == 'low',
                  onSelected: (selected) {
                    ref.read(priorityFilterProvider.notifier).state = selected
                        ? 'low'
                        : null;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(statusFilterProvider.notifier).state = null;
            ref.read(categoryFilterProvider.notifier).state = null;
            ref.read(priorityFilterProvider.notifier).state = null;
            Navigator.pop(context);
          },
          child: const Text('Clear All'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _chip({
    required BuildContext context,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
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
