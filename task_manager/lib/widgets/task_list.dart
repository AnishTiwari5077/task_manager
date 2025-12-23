import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_manager/config/theme.dart';
import 'package:task_manager/providers/task_provider.dart';
import '../models/task.dart';

class TaskList extends ConsumerWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;

  const TaskList({super.key, required this.tasks, required this.onTaskTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(task: task, onTap: () => onTaskTap(task));
      },
    );
  }
}

class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({super.key, required this.task, required this.onTap});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'scheduling':
        return const Color(0xFF3B82F6); // Blue
      case 'finance':
        return AppTheme.successColor;
      case 'technical':
        return AppTheme.secondaryColor;
      case 'safety':
        return AppTheme.errorColor;
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      default:
        return AppTheme.infoColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.sync;
      default:
        return Icons.pending_actions;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'in_progress':
        return AppTheme.infoColor;
      default:
        return AppTheme.warningColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _getCategoryColor(task.category);
    final priorityColor = _getPriorityColor(task.priority);
    final statusColor = _getStatusColor(task.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if task has classification data
    final hasEntities =
        task.extractedEntities != null && task.extractedEntities!.isNotEmpty;
    final hasActions =
        task.suggestedActions != null && task.suggestedActions!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: .3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      task.category.toUpperCase(),
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 12, color: priorityColor),
                        const SizedBox(width: 4),
                        Text(
                          task.priority.toUpperCase(),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(task.status),
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // More Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.delete, color: AppTheme.errorColor),
                                SizedBox(width: 12),
                                Text('Delete Task'),
                              ],
                            ),
                            content: const Text(
                              'Are you sure you want to delete this tasks? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.errorColor,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await ref
                              .read(taskNotifierProvider.notifier)
                              .deleteTask(task.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Task deleted successfully'),
                                  ],
                                ),
                                backgroundColor: AppTheme.successColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } else if (value == 'complete') {
                        await ref
                            .read(taskNotifierProvider.notifier)
                            .updateTaskStatus(task.id, 'completed');
                      } else if (value == 'in_progress') {
                        await ref
                            .read(taskNotifierProvider.notifier)
                            .updateTaskStatus(task.id, 'in_progress');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'in_progress',
                        child: Row(
                          children: [
                            Icon(
                              Icons.sync,
                              size: 18,
                              color: AppTheme.infoColor,
                            ),
                            SizedBox(width: 12),
                            Text('Mark In Progress'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppTheme.successColor,
                            ),
                            SizedBox(width: 12),
                            Text('Mark Complete'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: AppTheme.errorColor,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Title
              Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: task.status == 'completed'
                      ? TextDecoration.lineThrough
                      : null,
                  decorationThickness: 2,
                  height: 1.4,
                ),
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              if (hasEntities) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _buildEntityChips(task.extractedEntities!, isDark),
                ),
              ],

              if (hasActions) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.suggestedActions!.take(2).join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),
              // Footer Info
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (task.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM dd, yyyy').format(task.dueDate!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  if (task.assignedTo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.assignedTo!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEntityChips(Map<String, dynamic> entities, bool isDark) {
    final chips = <Widget>[];

    entities.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        // Take only first 2 items from each entity type
        for (final item in value.take(2)) {
          chips.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.infoColor.withValues(alpha: .3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEntityIcon(key),
                    size: 10,
                    color: AppTheme.infoColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    });

    return chips;
  }

  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'dates':
        return Icons.calendar_today;
      case 'times':
        return Icons.access_time;
      case 'people':
        return Icons.person;
      case 'locations':
        return Icons.location_on;
      default:
        return Icons.info_outline;
    }
  }
}
