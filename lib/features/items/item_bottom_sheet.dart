import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/sync/google_calendar_service.dart';

class ItemBottomSheet extends ConsumerStatefulWidget {
  final CalendarItem? initialItem;
  final DateTime? prefilledStart;
  final DateTime? prefilledEnd;

  const ItemBottomSheet({
    super.key,
    this.initialItem,
    this.prefilledStart,
    this.prefilledEnd,
  });

  /// Static helper to show the sheet
  static Future<void> show(
    BuildContext context, {
    CalendarItem? initialItem,
    DateTime? prefilledStart,
    DateTime? prefilledEnd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ItemBottomSheet(
          initialItem: initialItem,
          prefilledStart: prefilledStart,
          prefilledEnd: prefilledEnd,
        ),
      ),
    );
  }

  @override
  ConsumerState<ItemBottomSheet> createState() => _ItemBottomSheetState();
}

class _ItemBottomSheetState extends ConsumerState<ItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late bool _isTask;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  late bool _isUnscheduled;
  late bool _isAllDay;
  late DateTime _selectedDate;
  late TimeOfDay _selectedStartTime;
  late TimeOfDay _selectedEndTime;
  
  late TaskCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;

    _isTask = item != null ? item.type == CalendarItemType.task : true;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    
    // Check backlog status
    _isUnscheduled = item != null ? (item.startAt == null) : (widget.prefilledStart == null);
    _isAllDay = item?.isAllDay ?? false;
    
    // Set up times
    final now = DateTime.now();
    final start = item?.startAt ?? widget.prefilledStart ?? now;
    final end = item?.endAt ?? widget.prefilledEnd ?? start.add(const Duration(minutes: 30));

    _selectedDate = DateTime(start.year, start.month, start.day);
    _selectedStartTime = TimeOfDay.fromDateTime(start);
    _selectedEndTime = TimeOfDay.fromDateTime(end);
    
    _selectedCategory = item?.category ?? TaskCategory.none;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _getCategoryShape(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return '■ ';
      case TaskCategory.personal:
        return '● ';
      case TaskCategory.errand:
        return '▲ ';
      case TaskCategory.none:
        return '';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        // Adjust end time to maintain default 30-min duration if it would be before start time
        final startMin = _selectedStartTime.hour * 60 + _selectedStartTime.minute;
        final endMin = _selectedEndTime.hour * 60 + _selectedEndTime.minute;
        if (endMin <= startMin) {
          final newEndMin = (startMin + 30) % 1440;
          _selectedEndTime = TimeOfDay(hour: newEndMin ~/ 60, minute: newEndMin % 60);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
    );
    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(calendarItemRepositoryProvider);
    final syncService = ref.read(googleCalendarServiceProvider);

    DateTime? start;
    DateTime? end;

    if (!_isUnscheduled) {
      start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedStartTime.hour,
        _selectedStartTime.minute,
      );

      end = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedEndTime.hour,
        _selectedEndTime.minute,
      );

      // Handle end date wrap-around to next day if end time is before start time
      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }
    }

    final item = widget.initialItem;
    final now = DateTime.now();

    if (item == null) {
      // Create new
      final newItem = CalendarItem(
        localId: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        type: _isTask ? CalendarItemType.task : CalendarItemType.event,
        googleCalendarId: 'quicktasks', // Repository will resolve this to the actual ID
        isExternalEvent: false,
        startAt: start,
        endAt: end,
        isAllDay: _isAllDay,
        isComplete: false,
        completedAt: null,
        category: _isTask ? _selectedCategory : TaskCategory.none,
        syncStatus: SyncStatus.pendingCreate,
        createdAt: now,
        updatedAt: now,
      );

      await repo.createItem(newItem);
    } else {
      // Update existing
      final updatedItem = item.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        type: _isTask ? CalendarItemType.task : CalendarItemType.event,
        startAt: start,
        endAt: end,
        isAllDay: _isAllDay,
        category: _isTask ? _selectedCategory : TaskCategory.none,
        updatedAt: now,
      );

      await repo.updateItem(updatedItem);
    }

    if (mounted) Navigator.pop(context);
    
    // Trigger background sync
    syncService.sync();
  }

  void _delete() async {
    final item = widget.initialItem;
    if (item == null) return;

    final repo = ref.read(calendarItemRepositoryProvider);
    final syncService = ref.read(googleCalendarServiceProvider);

    await repo.deleteItem(item.localId);

    if (mounted) Navigator.pop(context);
    
    // Trigger background sync
    syncService.sync();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Type Toggle
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _isTask ? theme.colorScheme.primary : Colors.transparent,
                        foregroundColor: _isTask ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                      ),
                      onPressed: () => setState(() {
                        _isTask = true;
                      }),
                      child: const Text('TASK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !_isTask ? theme.colorScheme.primary : Colors.transparent,
                        foregroundColor: !_isTask ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                      ),
                      onPressed: () => setState(() {
                        _isTask = false;
                        _isUnscheduled = false; // Events cannot be unscheduled
                      }),
                      child: const Text('EVENT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'TITLE',
                  hintText: 'Enter title',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // 3. Description Field
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'DESCRIPTION',
                  hintText: 'Enter description (optional)',
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              // 4. Backlog and All-Day Toggles
              if (_isTask) ...[
                CheckboxListTile(
                  title: const Text('ADD TO BACKLOG (UNSCHEDULED)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  value: _isUnscheduled,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _isUnscheduled = val;
                        if (val) {
                          _isAllDay = false;
                        }
                      });
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
              if (!_isUnscheduled) ...[
                CheckboxListTile(
                  title: const Text('ALL-DAY EVENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  value: _isAllDay,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _isAllDay = val;
                      });
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],

              // 5. Date & Time selectors
              if (!_isUnscheduled) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickDate,
                        child: Text('DATE: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ],
                ),
                if (!_isAllDay) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickStartTime,
                          child: Text('START: ${_selectedStartTime.format(context)}'),
                        ),
                      ),
                      if (!_isTask) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickEndTime,
                            child: Text('END: ${_selectedEndTime.format(context)}'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 20),

              // 6. Category Selector (Tasks only)
              if (_isTask) ...[
                const Text('CATEGORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: TaskCategory.values.map((cat) {
                    final shape = _getCategoryShape(cat);
                    final name = cat.name.toUpperCase();
                    final isSelected = _selectedCategory == cat;
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        foregroundColor: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => setState(() => _selectedCategory = cat),
                      child: Text('$shape$name', style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // 7. Save / Delete / Cancel Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.initialItem != null) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                      ),
                      onPressed: _delete,
                      child: const Text('DELETE'),
                    ),
                    const Spacer(),
                  ],
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _save,
                    child: const Text('SAVE'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
