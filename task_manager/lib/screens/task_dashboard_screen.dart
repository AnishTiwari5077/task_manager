import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:task_manager/providers/task_provider.dart';
import 'package:task_manager/widgets/task_form_button_sheet.dart';

import '../models/task.dart';
import '../widgets/summary_cards.dart';
import '../widgets/task_list.dart';

import '../widgets/filter_chips.dart';

class TaskDashboardScreen extends ConsumerStatefulWidget {
  const TaskDashboardScreen({super.key});

  @override
  ConsumerState<TaskDashboardScreen> createState() =>
      _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends ConsumerState<TaskDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTaskForm({Task? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormBottomSheet(task: task),
    );
  }

  Future<void> _refreshTasks() async {
    ref.invalidate(tasksProvider);
  }

  void _showFilterDialog() {
    showDialog(context: context, builder: (context) => const FilterDialog());
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final connectivity = ref.watch(connectivityProvider);
    final isOffline =
        connectivity.value?.contains(ConnectivityResult.none) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Manager'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Offline indicator
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'No internet connection',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Summary Cards
          const SummaryCards(),

          // Filter Chips
          const FilterChips(),

          // Task List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTasks,
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first task to get started',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }
                  return TaskList(
                    tasks: tasks,
                    onTaskTap: (task) => _showTaskForm(task: task),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading tasks',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refreshTasks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}

// Filter Dialog
class FilterDialog extends ConsumerWidget {
  const FilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(statusFilterProvider);
    final categoryFilter = ref.watch(categoryFilterProvider);
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
