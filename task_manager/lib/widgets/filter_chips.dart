import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/providers/task_provider.dart';

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryFilter = ref.watch(categoryFilterProvider);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: categoryFilter == null,
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Scheduling'),
            avatar: const Icon(Icons.schedule, size: 16),
            selected: categoryFilter == 'scheduling',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'scheduling'
                  : null;
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Finance'),
            avatar: const Icon(Icons.attach_money, size: 16),
            selected: categoryFilter == 'finance',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'finance'
                  : null;
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Technical'),
            avatar: const Icon(Icons.build, size: 16),
            selected: categoryFilter == 'technical',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'technical'
                  : null;
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Safety'),
            avatar: const Icon(Icons.security, size: 16),
            selected: categoryFilter == 'safety',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'safety'
                  : null;
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('General'),
            avatar: const Icon(Icons.label, size: 16),
            selected: categoryFilter == 'general',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'general'
                  : null;
            },
          ),
        ],
      ),
    );
  }
}
