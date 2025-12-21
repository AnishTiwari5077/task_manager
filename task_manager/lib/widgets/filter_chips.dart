import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/config/theme.dart';
import 'package:task_manager/providers/task_provider.dart';

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryFilter = ref.watch(categoryFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'All',
            icon: Icons.grid_view,
            isSelected: categoryFilter == null,
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = null;
            },
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Scheduling',
            icon: Icons.schedule,
            isSelected: categoryFilter == 'scheduling',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'scheduling'
                  : null;
            },
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Finance',
            icon: Icons.attach_money,
            isSelected: categoryFilter == 'finance',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'finance'
                  : null;
            },
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Technical',
            icon: Icons.build,
            isSelected: categoryFilter == 'technical',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'technical'
                  : null;
            },
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Safety',
            icon: Icons.security,
            isSelected: categoryFilter == 'safety',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'safety'
                  : null;
            },
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'General',
            icon: Icons.label,
            isSelected: categoryFilter == 'general',
            onSelected: (selected) {
              ref.read(categoryFilterProvider.notifier).state = selected
                  ? 'general'
                  : null;
            },
            color: const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Function(bool) onSelected,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? color
                : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? color
                  : (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: isDark
          ? AppTheme.darkSurface
          : AppTheme.lightCardBackground,
      selectedColor: color.withValues(alpha: .15),
      checkmarkColor: color,
      side: BorderSide(
        color: isSelected
            ? color.withValues(alpha: .5)
            : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        width: isSelected ? 1.5 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
    );
  }
}
