import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        return const Color(0xFF3B82F6);
      case 'finance':
        return AppTheme.successColor;
      case 'technical':
        return AppTheme.secondaryColor;
      case 'safety':
        return AppTheme.errorColor;
      default:
        return const Color(0xFF64748B);
    }
  }

  /// FA icons chosen for semantic accuracy and visual distinctiveness
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'scheduling':
        return FontAwesomeIcons.calendarCheck; // booked appointment
      case 'finance':
        return FontAwesomeIcons.sackDollar; // money / budget
      case 'technical':
        return FontAwesomeIcons.microchip; // hardware/software engineering
      case 'safety':
        return FontAwesomeIcons.shieldHalved; // protection / safety
      default:
        return FontAwesomeIcons.layerGroup; // stacked = general/misc
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

  /// Arrows communicate urgency level at a glance without reading text
  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return FontAwesomeIcons.anglesUp; // ▲▲ urgent
      case 'medium':
        return FontAwesomeIcons.equals; // = balanced
      default:
        return FontAwesomeIcons.anglesDown; // ▼▼ low
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return FontAwesomeIcons.circleCheck; // done / verified
      case 'in_progress':
        return FontAwesomeIcons.bolt; // active / fast
      default:
        return FontAwesomeIcons.hourglassHalf; // waiting
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

  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'dates':
        return FontAwesomeIcons.calendarDays; // multi-day calendar
      case 'times':
        return FontAwesomeIcons.clock; // classic clock
      case 'people':
        return FontAwesomeIcons.userTag; // person with label = assignee
      case 'locations':
        return FontAwesomeIcons.locationDot; // pin drop
      default:
        return FontAwesomeIcons.tag; // generic tag
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _getCategoryColor(task.category);
    final priorityColor = _getPriorityColor(task.priority);
    final statusColor = _getStatusColor(task.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              // ── Top row: category · priority · status · menu ──
              Row(
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          _getCategoryIcon(task.category),
                          size: 11,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.category.toUpperCase(),
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority badge
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
                        FaIcon(
                          _getPriorityIcon(task.priority),
                          size: 11,
                          color: priorityColor,
                        ),
                        const SizedBox(width: 5),
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
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                      _getStatusIcon(task.status),
                      color: statusColor,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Overflow menu
                  PopupMenuButton<String>(
                    icon: FaIcon(
                      FontAwesomeIcons.ellipsis, // horizontal 3-dots
                      size: 18,
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
                            title: Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.triangleExclamation,
                                  color: AppTheme.errorColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text('Delete Task'),
                              ],
                            ),
                            content: const Text(
                              'Are you sure you want to delete this task? This action cannot be undone.',
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
                                content: Row(
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.circleCheck,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Task deleted successfully'),
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
                      PopupMenuItem(
                        value: 'in_progress',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.bolt,
                              size: 15,
                              color: AppTheme.infoColor,
                            ),
                            const SizedBox(width: 12),
                            const Text('Mark In Progress'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.circleCheck,
                              size: 15,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 12),
                            const Text('Mark Complete'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.trashCan,
                              size: 15,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(width: 12),
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

              // Entity chips
              if (hasEntities) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _buildEntityChips(task.extractedEntities!, isDark),
                ),
              ],

              // Suggested actions hint
              if (hasActions) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons
                          .wandMagicSparkles, // magic wand = AI suggestions
                      size: 12,
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

              // Footer: due date + assignee
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (task.dueDate != null)
                    _FooterChip(
                      icon: FontAwesomeIcons.calendarDays, // date
                      label: DateFormat('MMM dd, yyyy').format(task.dueDate!),
                      isDark: isDark,
                    ),
                  if (task.assignedTo != null)
                    _FooterChip(
                      icon: FontAwesomeIcons
                          .userTie, // person with tie = assignee
                      label: task.assignedTo!,
                      isDark: isDark,
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
                  FaIcon(
                    _getEntityIcon(key),
                    size: 9,
                    color: AppTheme.infoColor,
                  ),
                  const SizedBox(width: 5),
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
}

class _FooterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _FooterChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 12,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
