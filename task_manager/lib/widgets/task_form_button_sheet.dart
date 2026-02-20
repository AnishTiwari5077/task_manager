import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  Map<String, dynamic>? _autoClassification;
  bool _showAutoClassification = false;
  bool _assignedToManuallyEdited = false;
  bool _isAutoFilling = false;

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

      if (widget.task!.assignedTo != null &&
          widget.task!.assignedTo!.isNotEmpty) {
        _assignedToManuallyEdited = true;
      }
    }

    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
    _assignedToController.addListener(_onAssignedToChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _descriptionController.removeListener(_onTextChanged);
    _assignedToController.removeListener(_onAssignedToChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  void _onAssignedToChanged() {
    if (!_isAutoFilling) {
      _assignedToManuallyEdited = true;
    }
  }

  void _onTextChanged() {
    if (_titleController.text.trim().length >= 3) {
      _performAutoClassification();
    }
  }

  void _performAutoClassification() {
    final classification = ref
        .read(classificationNotifierProvider.notifier)
        .classifyTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );

    setState(() {
      _autoClassification = classification;
      _showAutoClassification = true;
      _category = classification['category'] as String?;
      _priority = classification['priority'] as String?;

      final entities =
          classification['extracted_entities'] as Map<String, dynamic>?;

      if (entities != null && _dueDate == null) {
        final dates = entities['dates'] as List?;
        if (dates != null && dates.isNotEmpty) {
          _dueDate = _parseDateFromText(dates.first.toString());
        }
      }

      if (entities != null && !_assignedToManuallyEdited) {
        final people = entities['people'] as List?;
        if (people != null && people.isNotEmpty) {
          final name = _capitalizeName(people.first.toString());
          _isAutoFilling = true;
          _assignedToController.text = name;
          _isAutoFilling = false;
        }
      }
    });
  }

  String _capitalizeName(String name) {
    return name
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  DateTime? _parseDateFromText(String dateText) {
    final now = DateTime.now();
    final text = dateText.toLowerCase().trim();

    if (text == 'today') return now;
    if (text == 'tomorrow') return now.add(const Duration(days: 1));
    if (text == 'yesterday') return now.subtract(const Duration(days: 1));

    if (text == 'monday') return _getNextWeekday(DateTime.monday);
    if (text == 'tuesday') return _getNextWeekday(DateTime.tuesday);
    if (text == 'wednesday') return _getNextWeekday(DateTime.wednesday);
    if (text == 'thursday') return _getNextWeekday(DateTime.thursday);
    if (text == 'friday') return _getNextWeekday(DateTime.friday);
    if (text == 'saturday') return _getNextWeekday(DateTime.saturday);
    if (text == 'sunday') return _getNextWeekday(DateTime.sunday);

    if (text.contains('next week')) return now.add(const Duration(days: 7));
    if (text.contains('this week')) return now.add(const Duration(days: 3));
    if (text.contains('next month')) {
      return DateTime(now.year, now.month + 1, now.day);
    }

    final monthMap = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final monthDayPattern = RegExp(
      r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{1,2})',
      caseSensitive: false,
    );
    final monthDayMatch = monthDayPattern.firstMatch(text);
    if (monthDayMatch != null) {
      final month = monthMap[monthDayMatch.group(1)!.substring(0, 3)];
      final day = int.parse(monthDayMatch.group(2)!);
      if (month != null) {
        var year = now.year;
        final possibleDate = DateTime(year, month, day);
        if (possibleDate.isBefore(now)) year++;
        return DateTime(year, month, day);
      }
    }

    final fullDatePattern = RegExp(
      r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{1,2})[,\s]+(\d{4})',
      caseSensitive: false,
    );
    final fullMatch = fullDatePattern.firstMatch(text);
    if (fullMatch != null) {
      final month = monthMap[fullMatch.group(1)!.substring(0, 3)];
      final day = int.parse(fullMatch.group(2)!);
      final year = int.parse(fullMatch.group(3)!);
      if (month != null) return DateTime(year, month, day);
    }

    try {
      if (text.contains('/') || text.contains('-')) {
        final separator = text.contains('/') ? '/' : '-';
        final parts = text.split(separator);
        if (parts.length == 3) {
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          var year = int.parse(parts[2]);
          if (year < 100) year += 2000;
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}

    return null;
  }

  DateTime _getNextWeekday(int weekday) {
    final now = DateTime.now();
    int daysUntil = (weekday - now.weekday) % 7;
    if (daysUntil == 0) daysUntil = 7;
    return now.add(Duration(days: daysUntil));
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final taskData = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    final assignedTo = _assignedToController.text.trim();
    if (assignedTo.isNotEmpty) {
      taskData['assigned_to'] = assignedTo;
    }

    if (_dueDate != null) {
      taskData['due_date'] = _dueDate!.toIso8601String();
    }

    if (_category != null) taskData['category'] = _category!;
    if (_priority != null) taskData['priority'] = _priority!;
    if (widget.task != null) taskData['status'] = _status;

    if (_autoClassification != null) {
      final extractedEntities = _autoClassification!['extracted_entities'];
      if (extractedEntities != null && extractedEntities is Map) {
        taskData['extracted_entities'] = Map<String, dynamic>.from(
          extractedEntities,
        );
      }
      final suggestedActions = _autoClassification!['suggested_actions'];
      if (suggestedActions != null && suggestedActions is List) {
        taskData['suggested_actions'] = List<String>.from(
          suggestedActions.map((e) => e.toString()),
        );
      }
    }

    try {
      if (widget.task == null) {
        await ref.read(taskNotifierProvider.notifier).createTask(taskData);
        if (mounted) {
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
                  const Text('Task created successfully'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        await ref
            .read(taskNotifierProvider.notifier)
            .updateTask(widget.task!.id, taskData);
        if (mounted) {
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
                  const Text('Task updated successfully'),
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
                const FaIcon(
                  FontAwesomeIcons.circleXmark,
                  color: Colors.white,
                  size: 16,
                ),
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
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
                      child: FaIcon(
                        // clipboardList = new task form; penToSquare = editing
                        widget.task == null
                            ? FontAwesomeIcons.clipboardList
                            : FontAwesomeIcons.penToSquare,
                        color: AppTheme.primaryColor,
                        size: 20,
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
                      icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
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

              // Form body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    20 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title ──
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: 'Enter task title',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 13,
                              ),
                              child: FaIcon(
                                FontAwesomeIcons
                                    .penNib, // pen nib = title/heading
                                size: 16,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
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
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),

                        // ── Description ──
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Enter task description',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 13,
                              ),
                              child: FaIcon(
                                FontAwesomeIcons
                                    .alignLeft, // paragraph lines = body text
                                size: 16,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 20),

                        // ── Auto-Classification card ──
                        if (_showAutoClassification &&
                            _autoClassification != null) ...[
                          _buildAutoClassificationCard(isDark),
                          const SizedBox(height: 24),
                        ],

                        Text(
                          _showAutoClassification
                              ? 'Override Classification'
                              : 'Classification',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),

                        // ── Category ──
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          itemHeight: 59.6,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 13,
                              ),
                              child: FaIcon(
                                FontAwesomeIcons
                                    .layerGroup, // stacked layers = grouping
                                size: 16,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
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
                          onChanged: (value) =>
                              setState(() => _category = value),
                        ),
                        const SizedBox(height: 20),

                        // ── Priority ──
                        DropdownButtonFormField<String>(
                          initialValue: _priority,
                          itemHeight: 59.6,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 13,
                              ),
                              child: FaIcon(
                                FontAwesomeIcons
                                    .arrowUpWideShort, // sorted arrows = priority rank
                                size: 16,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
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
                            DropdownMenuItem(value: 'low', child: Text('Low')),
                          ],
                          onChanged: (value) =>
                              setState(() => _priority = value),
                        ),
                        const SizedBox(height: 20),

                        // ── Due Date ──
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Due Date',
                              hintText: 'Select date',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 13,
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons
                                      .calendarDays, // calendar with day grid
                                  size: 16,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                              suffixIcon: _dueDate != null
                                  ? IconButton(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.xmark,
                                        size: 14,
                                      ),
                                      onPressed: () =>
                                          setState(() => _dueDate = null),
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

                        // ── Assigned To ──
                        TextFormField(
                          controller: _assignedToController,
                          decoration: InputDecoration(
                            labelText: 'Assigned To',
                            hintText: 'Enter assignee name',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 13,
                              ),
                              child: FaIcon(
                                FontAwesomeIcons
                                    .userTie, // person with tie = assignee role
                                size: 16,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            suffixIcon: _assignedToController.text.isNotEmpty
                                ? IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.xmark,
                                      size: 14,
                                    ),
                                    tooltip: 'Clear assignee',
                                    onPressed: () {
                                      _assignedToController.clear();
                                      setState(() {
                                        _assignedToManuallyEdited = false;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          textInputAction: TextInputAction.done,
                          onTap: () {
                            if (_assignedToController.text.isNotEmpty) {
                              _assignedToManuallyEdited = true;
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Status (edit mode only) ──
                        if (widget.task != null) ...[
                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            itemHeight: 59.6,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 13,
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons
                                      .circleHalfStroke, // half circle = status
                                  size: 16,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
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

                        // ── Submit ──
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
                                      FaIcon(
                                        // floppyDisk = save/create; penToSquare = edit/update
                                        widget.task == null
                                            ? FontAwesomeIcons.floppyDisk
                                            : FontAwesomeIcons.penToSquare,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        widget.task == null
                                            ? 'Create Task'
                                            : 'Update Task',
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

  Widget _buildAutoClassificationCard(bool isDark) {
    final classification = _autoClassification!;
    final confidence = classification['confidence'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.infoColor.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  FontAwesomeIcons
                      .wandMagicSparkles, // magic wand = AI auto-classify
                  size: 16,
                  color: AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Auto-Classification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (confidence != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${((confidence['category'] as double) * 100).toInt()}% confident',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  FontAwesomeIcons.layerGroup,
                  'Category',
                  classification['category'] as String,
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoRow(
                  FontAwesomeIcons.arrowUpWideShort,
                  'Priority',
                  classification['priority'] as String,
                  isDark,
                ),
              ),
            ],
          ),

          if (classification['extracted_entities'] != null &&
              (classification['extracted_entities'] as Map).isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: AppTheme.infoColor.withValues(alpha: .2)),
            const SizedBox(height: 12),
            Text(
              'Extracted Information',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildExtractedEntities(
              classification['extracted_entities'] as Map<String, dynamic>,
              isDark,
            ),
          ],

          if (classification['suggested_actions'] != null &&
              (classification['suggested_actions'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: AppTheme.infoColor.withValues(alpha: .2)),
            const SizedBox(height: 12),
            Text(
              'Suggested Actions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (classification['suggested_actions'] as List).map((
                action,
              ) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons
                            .squareCheck, // checked box = actionable item
                        size: 12,
                        color: AppTheme.infoColor,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        action.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.infoColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: AppTheme.infoColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              Text(
                value.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedEntities(Map<String, dynamic> entities, bool isDark) {
    final items = <Widget>[];

    entities.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaIcon(
                  _getEntityIcon(key),
                  size: 13,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: value
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.infoColor,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(children: items);
  }

  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'dates':
        return FontAwesomeIcons.calendarDays; // calendar grid = dates
      case 'times':
        return FontAwesomeIcons.clock; // classic clock face = time
      case 'people':
        return FontAwesomeIcons.userTag; // person with tag = named person
      case 'locations':
        return FontAwesomeIcons.locationDot; // pin drop = place
      default:
        return FontAwesomeIcons.tag; // generic tag
    }
  }
}
