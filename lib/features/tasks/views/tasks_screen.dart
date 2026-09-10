import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/user_permissions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/tasks_repository.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _filter = 'pending'; // 'pending' | 'completed' | 'all'

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final canDelete = ref.watch(canDeleteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            onPressed: () => context.push(AppRoutes.taskCreate),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Pending')),
                ButtonSegment(value: 'completed', label: Text('Completed')),
                ButtonSegment(value: 'all', label: Text('All')),
              ],
              selected: {_filter},
              onSelectionChanged: (newVal) {
                setState(() => _filter = newVal.first);
              },
            ),
          ),

          // Tasks List
          Expanded(
            child: tasksAsync.when(
              data: (allTasks) {
                var filtered = allTasks;
                if (_filter == 'pending') {
                  filtered = filtered.where((t) => !t.isCompleted).toList();
                } else if (_filter == 'completed') {
                  filtered = filtered.where((t) => t.isCompleted).toList();
                }

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    title: _filter == 'completed' ? 'No Completed Tasks' : 'All Caught Up!',
                    description: _filter == 'completed'
                        ? 'Completed tasks will appear here.'
                        : 'Schedule follow-up calls, emails, or meetings.',
                    icon: Icons.checklist_rounded,
                    actionLabel: 'New Task',
                    onAction: () => context.push(AppRoutes.taskCreate),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(tasksStreamProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      return _buildTaskCard(context, task, canDelete);
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(message: 'Loading tasks...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(tasksStreamProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.taskCreate),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, bool canDelete) {
    final cardContent = Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(
          value: task.isCompleted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (val) {
            if (val != null) {
              ref.read(tasksRepositoryProvider).toggleTaskCompletion(task.id, val);
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: task.isOverdue ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  task.dueDate != null ? Formatters.date(task.dueDate) : 'No due date',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.isOverdue ? Colors.red : Colors.grey,
                    fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: StatusBadge(status: task.type),
      ),
    );

    if (!canDelete) {
      return cardContent;
    }

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(tasksRepositoryProvider).deleteTask(task.id);
        context.showSnackBar('Task deleted');
      },
      child: cardContent,
    );
  }
}
