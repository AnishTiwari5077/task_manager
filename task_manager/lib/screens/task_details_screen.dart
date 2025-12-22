import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_manager/config/theme.dart';
import 'package:task_manager/providers/task_provider.dart';
import '../models/task.dart';

class TaskDetailScreen extends ConsumerWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(task.category);
    final priorityColor = _getPriorityColor(task.priority);
    final statusColor = _getStatusColor(task.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text(
                      'Are you sure you want to delete this task?',
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
                    Navigator.pop(context);
                  }
                }
              } else if (value == 'reclassify') {
                await ref
                    .read(taskNotifierProvider.notifier)
                    .reclassifyTask(task.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task reclassified successfully'),
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reclassify',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18),
                    SizedBox(width: 12),
                    Text('Reclassify'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    categoryColor.withValues(alpha: isDark ? 0.1 : 0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppTheme.darkDivider
                        : AppTheme.lightDivider,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        task.category.toUpperCase(),
                        categoryColor,
                        Icons.category,
                      ),
                      _buildBadge(
                        task.priority.toUpperCase(),
                        priorityColor,
                        Icons.flag,
                      ),
                      _buildBadge(
                        task.status.replaceAll('_', ' ').toUpperCase(),
                        statusColor,
                        Icons.circle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Description Section
            if (task.description != null && task.description!.isNotEmpty)
              _buildSection(
                context,
                'Description',
                Icons.description,
                isDark,
                child: Text(
                  task.description!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
              ),

            // Details Section
            _buildSection(
              context,
              'Details',
              Icons.info_outline,
              isDark,
              child: Column(
                children: [
                  if (task.dueDate != null)
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Due Date',
                      DateFormat('EEEE, MMM dd, yyyy').format(task.dueDate!),
                      isDark,
                    ),
                  if (task.assignedTo != null)
                    _buildDetailRow(
                      Icons.person,
                      'Assigned To',
                      task.assignedTo!,
                      isDark,
                    ),
                  _buildDetailRow(
                    Icons.access_time,
                    'Created',
                    DateFormat('MMM dd, yyyy • hh:mm a').format(task.createdAt),
                    isDark,
                  ),
                  _buildDetailRow(
                    Icons.update,
                    'Last Updated',
                    DateFormat('MMM dd, yyyy • hh:mm a').format(task.updatedAt),
                    isDark,
                  ),
                ],
              ),
            ),

            // Extracted Entities Section
            if (task.extractedEntities != null &&
                task.extractedEntities!.isNotEmpty)
              _buildSection(
                context,
                'Extracted Information',
                Icons.auto_awesome,
                isDark,
                child: _buildExtractedEntities(task.extractedEntities!, isDark),
              ),

            // Suggested Actions Section
            if (task.suggestedActions != null &&
                task.suggestedActions!.isNotEmpty)
              _buildSection(
                context,
                'Suggested Actions',
                Icons.checklist,
                isDark,
                child: Column(
                  children: task.suggestedActions!
                      .map((action) => _buildActionItem(action, isDark))
                      .toList(),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightCardBackground,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
          ),
        ),
        child: Row(
          children: [
            if (task.status != 'in_progress')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(taskNotifierProvider.notifier)
                        .updateTaskStatus(task.id, 'in_progress');
                  },
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.infoColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (task.status != 'in_progress') const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref
                      .read(taskNotifierProvider.notifier)
                      .updateTaskStatus(task.id, 'completed');
                },
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    bool isDark, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedEntities(Map<String, dynamic> entities, bool isDark) {
    final items = <Widget>[];

    entities.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: value
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.infoColor.withValues(alpha: .3),
                            ),
                          ),
                          child: Text(
                            item.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.infoColor,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildActionItem(String action, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 16,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ],
      ),
    );
  }
}
