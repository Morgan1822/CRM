import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/user_permissions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
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
        title: const Text('Tasks & Follow-ups'),
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
            child: Row(
              children: [
                _buildFilterChip('pending', 'Pending Tasks'),
                _buildFilterChip('completed', 'Completed'),
                _buildFilterChip('all', 'All Tasks'),
              ],
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
                        ? 'Completed follow-up tasks will appear here.'
                        : 'Schedule follow-up calls, meetings, or reminders.',
                    icon: Icons.checklist_rounded,
                    actionLabel: 'New Task',
                    onAction: () => context.push(AppRoutes.taskCreate),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(tasksStreamProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRoutes.taskCreate),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primarySubtle,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.lightTextSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(
            color: isSelected ? const Color(0xFFBFDBFE) : AppColors.lightBorder,
          ),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _filter = key);
          }
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, bool canDelete) {
    final theme = context.theme;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Transform.scale(
          scale: 1.1,
          child: Checkbox(
            value: task.isCompleted,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            onChanged: (val) {
              if (val != null) {
                ref.read(tasksRepositoryProvider).toggleTaskCompletion(task.id, val);
              }
            },
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? AppColors.lightTextMuted : AppColors.lightTextPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  task.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: task.isOverdue ? AppColors.error : AppColors.lightTextMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  task.dueDate != null ? Formatters.date(task.dueDate) : 'No due date',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.isOverdue ? AppColors.error : AppColors.lightTextMuted,
                    fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: StatusBadge(status: task.type, isSmall: true),
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
          borderRadius: BorderRadius.circular(14),
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
