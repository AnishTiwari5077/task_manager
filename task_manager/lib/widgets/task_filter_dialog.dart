import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/providers/task_provider.dart';

class FilterDialog extends ConsumerWidget {
  const FilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(statusFilterProvider);
    final _ = ref.watch(categoryFilterProvider);
    final priorityFilter = ref.watch(priorityFilterProvider);

    return AlertDialog(
      title: const Text('Filter Tasks'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Pending'),
                  selected: statusFilter == 'pending',
                  onSelected: (selected) {
                    ref.read(statusFilterProvider.notifier).state = selected
                        ? 'pending'
                        : null;
                  },
                ),
                FilterChip(
                  label: const Text('In Progress'),
                  selected: statusFilter == 'in_progress',
                  onSelected: (selected) {
                    ref.read(statusFilterProvider.notifier).state = selected
                        ? 'in_progress'
                        : null;
                  },
                ),
                FilterChip(
                  label: const Text('Completed'),
                  selected: statusFilter == 'completed',
                  onSelected: (selected) {
                    ref.read(statusFilterProvider.notifier).state = selected
                        ? 'completed'
                        : null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Priority',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('High'),
                  selected: priorityFilter == 'high',
                  onSelected: (selected) {
                    ref.read(priorityFilterProvider.notifier).state = selected
                        ? 'high'
                        : null;
                  },
                ),
                FilterChip(
                  label: const Text('Medium'),
                  selected: priorityFilter == 'medium',
                  onSelected: (selected) {
                    ref.read(priorityFilterProvider.notifier).state = selected
                        ? 'medium'
                        : null;
                  },
                ),
                FilterChip(
                  label: const Text('Low'),
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
}
