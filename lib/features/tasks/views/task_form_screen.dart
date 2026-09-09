import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/tasks_repository.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _taskType = 'todo';
  DateTime? _dueDate = DateTime.now().add(const Duration(hours: 4));
  String? _selectedContactId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      final newTask = TaskModel(
        id: '',
        title: _titleController.text.trim(),
        type: _taskType,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _dueDate,
        contactId: _selectedContactId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTask(newTask);
      if (mounted) {
        context.showSnackBar('Task created successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Task Title *',
                hint: 'e.g. Follow up on proposal',
                validator: Validators.required,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _taskType,
                decoration: const InputDecoration(labelText: 'Task Type'),
                items: const [
                  DropdownMenuItem(value: 'todo', child: Text('To-Do')),
                  DropdownMenuItem(value: 'call', child: Text('Phone Call')),
                  DropdownMenuItem(value: 'email', child: Text('Send Email')),
                  DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _taskType = val);
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: Icon(Icons.event_rounded, size: 20),
                  ),
                  child: Text(
                    _dueDate != null ? Formatters.date(_dueDate) : 'Select date',
                    style: TextStyle(color: _dueDate != null ? null : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              contactsAsync.when(
                data: (contacts) {
                  return DropdownButtonFormField<String?>(
                    value: _selectedContactId,
                    decoration: const InputDecoration(
                      labelText: 'Related Contact (Optional)',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...contacts.map((c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.fullName),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedContactId = val),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
                hint: 'Add details or agenda items...',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Create Task',
                isLoading: _isLoading,
                onPressed: _saveTask,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
