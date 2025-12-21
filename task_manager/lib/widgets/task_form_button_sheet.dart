import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_manager/config/theme.dart';
import 'package:task_manager/providers/task_provider.dart';
import '../models/task.dart';

class TaskFormBottomSheet extends ConsumerStatefulWidget {
  final Task? task;

  const TaskFormBottomSheet({super.key, this.task});

  @override
  ConsumerState<TaskFormBottomSheet> createState() =>
      _TaskFormBottomSheetState();
}

class _TaskFormBottomSheetState extends ConsumerState<TaskFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _assignedToController;

  String? _category;
  String? _priority;
  String _status = 'pending';
  DateTime? _dueDate;
  bool _showClassification = false;
  Map<String, dynamic>? _classification;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _assignedToController = TextEditingController(
      text: widget.task?.assignedTo ?? '',
    );

    if (widget.task != null) {
      _category = widget.task!.category;
      _priority = widget.task!.priority;
      _status = widget.task!.status;
      _dueDate = widget.task!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final taskData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'assigned_to': _assignedToController.text.trim().isEmpty
          ? null
          : _assignedToController.text.trim(),
      'due_date': _dueDate?.toIso8601String(),
    };

    // Add category and priority if manually set
    if (_category != null) taskData['category'] = _category!;
    if (_priority != null) taskData['priority'] = _priority!;
    if (widget.task != null) taskData['status'] = _status;

    try {
      if (widget.task == null) {
        // Create new task - show classification first
        if (!_showClassification) {
          // Simulate classification (in real app, call API to get classification)
          setState(() {
            _showClassification = true;
            _classification = {
              'category': _category ?? 'general',
              'priority': _priority ?? 'low',
            };
          });
          return;
        }

        await ref.read(taskNotifierProvider.notifier).createTask(taskData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Task created successfully'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing task
        await ref
            .read(taskNotifierProvider.notifier)
            .updateTask(widget.task!.id, taskData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Task updated successfully'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskNotifier = ref.watch(taskNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkTextSecondary.withValues(alpha: .3)
                      : AppTheme.lightTextSecondary.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.task == null ? Icons.add_task : Icons.edit,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.task == null ? 'Create Task' : 'Edit Task',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightBackground,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'Enter task title',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            if (value.trim().length < 3) {
                              return 'Title must be at least 3 characters';
                            }
                            return null;
                          },
                          maxLength: 200,
                        ),
                        const SizedBox(height: 20),
                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Enter task description',
                            prefixIcon: Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Due Date
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Due Date',
                              hintText: 'Select date',
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon: _dueDate != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setState(() => _dueDate = null);
                                      },
                                    )
                                  : null,
                            ),
                            child: Text(
                              _dueDate == null
                                  ? 'No date selected'
                                  : DateFormat(
                                      'EEEE, MMM dd, yyyy',
                                    ).format(_dueDate!),
                              style: TextStyle(
                                color: _dueDate == null
                                    ? (isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Assigned To
                        TextFormField(
                          controller: _assignedToController,
                          decoration: const InputDecoration(
                            labelText: 'Assigned To',
                            hintText: 'Enter assignee name',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Classification Preview
                        if (_showClassification && _classification != null) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.infoColor.withValues(
                                    alpha: .1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 20,
                                  color: AppTheme.infoColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Auto-Classification',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withValues(alpha: .05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.infoColor.withValues(alpha: .2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      size: 20,
                                      color: AppTheme.infoColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Category: ',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    Expanded(
                                      child: Text(
                                        _classification!['category'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.infoColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.flag,
                                      size: 20,
                                      color: AppTheme.infoColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Priority: ',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    Expanded(
                                      child: Text(
                                        _classification!['priority'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.infoColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Override Classification',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          // Override options
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _category,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    prefixIcon: Icon(Icons.category, size: 20),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'scheduling',
                                      child: Text('Scheduling'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'finance',
                                      child: Text('Finance'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'technical',
                                      child: Text('Technical'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'safety',
                                      child: Text('Safety'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'general',
                                      child: Text('General'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _category = value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _priority,
                                  decoration: const InputDecoration(
                                    labelText: 'Priority',
                                    prefixIcon: Icon(Icons.flag, size: 20),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'high',
                                      child: Text('High'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'medium',
                                      child: Text('Medium'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'low',
                                      child: Text('Low'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _priority = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                        ],
                        // Status (only for edit)
                        if (widget.task != null) ...[
                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.sync_alt),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'in_progress',
                                child: Text('In Progress'),
                              ),
                              DropdownMenuItem(
                                value: 'completed',
                                child: Text('Completed'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                          ),
                          const SizedBox(height: 28),
                        ],
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: taskNotifier.isLoading
                                ? null
                                : _submitForm,
                            child: taskNotifier.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _showClassification
                                            ? Icons.check
                                            : Icons.arrow_forward,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _showClassification
                                            ? 'Create Task'
                                            : 'Continue',
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
