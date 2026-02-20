import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager/providers/task_provider.dart';
import 'package:task_manager/widgets/task_filter_dialog.dart';
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
            icon: const FaIcon(
              FontAwesomeIcons.sliders,
              size: 18,
            ), // sliders = filter controls
            tooltip: 'Filter',
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
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 16,
                  ), // classic search
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.xmark,
                          size: 16,
                        ), // clean X
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
          // Offline banner
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.wifi, // wifi icon for connection status
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'No internet connection',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          const SummaryCards(),
          const FilterChips(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTasks,
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons
                                  .boxOpen, // open empty box = nothing here
                              size: 56,
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
                      FaIcon(
                        FontAwesomeIcons
                            .circleXmark, // bold X circle = hard error
                        size: 56,
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
                        icon: const FaIcon(
                          FontAwesomeIcons.arrowsRotate,
                          size: 15,
                        ), // rotate arrows = retry/refresh
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
        icon: const FaIcon(FontAwesomeIcons.plus, size: 16), // clean plus
        label: const Text('New Task'),
      ),
    );
  }
}
