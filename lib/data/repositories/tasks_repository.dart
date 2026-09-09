import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_failure.dart';
import '../models/task_model.dart';
import '../services/supabase_service.dart';

class TasksRepository {
  final SupabaseClient _client;

  TasksRepository(this._client);

  Stream<List<TaskModel>> watchTasks({bool? onlyPending}) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('due_date', ascending: true)
        .map((rows) {
          var items = rows.map((json) => TaskModel.fromJson(json)).toList();
          if (onlyPending == true) {
            items = items.where((t) => !t.isCompleted).toList();
          }
          return items;
        });
  }

  Future<List<TaskModel>> getTasks() async {
    try {
      final data = await _client
          .from('tasks')
          .select('*, contact:contacts(first_name, last_name)')
          .order('due_date', ascending: true);
      return (data as List).map((json) => TaskModel.fromJson(json)).toList();
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final data = await _client
          .from('tasks')
          .insert(task.toJson(includeId: false))
          .select()
          .single();
      return TaskModel.fromJson(data);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<void> toggleTaskCompletion(String id, bool isCompleted) async {
    try {
      await _client
          .from('tasks')
          .update({
            'is_completed': isCompleted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _client.from('tasks').delete().eq('id', id);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }
}

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(ref.watch(supabaseClientProvider));
});

final tasksStreamProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.watchTasks();
});
