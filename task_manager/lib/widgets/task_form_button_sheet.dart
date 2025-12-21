import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
            const SnackBar(content: Text('Task created successfully')),
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
            const SnackBar(content: Text('Task updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskNotifier = ref.watch(taskNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      widget.task == null ? 'Create Task' : 'Edit Task',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title *',
                            border: OutlineInputBorder(),
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
                        const SizedBox(height: 16),
                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            border: OutlineInputBorder(),
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
                        const SizedBox(height: 16),
                        // Due Date
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _dueDate == null
                                  ? 'Select date'
                                  : DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(_dueDate!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Assigned To
                        TextFormField(
                          controller: _assignedToController,
                          decoration: const InputDecoration(
                            labelText: 'Assigned To',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Classification Preview
                        if (_showClassification && _classification != null) ...[
                          const Text(
                            'Auto-Classification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.category, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Category: '),
                                      Text(
                                        _classification!['category'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.flag, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Priority: '),
                                      Text(
                                        _classification!['priority'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Override options
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _category,
                                  decoration: const InputDecoration(
                                    labelText: 'Override Category',
                                    border: OutlineInputBorder(),
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
                                  value: _priority,
                                  decoration: const InputDecoration(
                                    labelText: 'Override Priority',
                                    border: OutlineInputBorder(),
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
                          const SizedBox(height: 24),
                        ],
                        // Status (only for edit)
                        if (widget.task != null) ...[
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
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
                          const SizedBox(height: 24),
                        ],
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: taskNotifier.isLoading
                                ? null
                                : _submitForm,
                            child: taskNotifier.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _showClassification
                                        ? 'Create Task'
                                        : 'Continue',
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
