import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/task_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;
  
  Future<List<Task>> getTasks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    
    return (response as List).map((task) => Task.fromJson(task)).toList();
  }
  
  Future<Task> createTask(String title) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final task = {
      'title': title,
      'is_completed': false,
      'user_id': user.id,
    };
    
    final response = await _supabase
        .from('tasks')
        .insert(task)
        .select()
        .single();
    
    return Task.fromJson(response);
  }
  
  Future<void> deleteTask(String taskId) async {
    await _supabase
        .from('tasks')
        .delete()
        .eq('id', taskId);
  }
  
  Future<Task> updateTaskStatus(String taskId, bool isCompleted) async {
    final response = await _supabase
        .from('tasks')
        .update({'is_completed': isCompleted})
        .eq('id', taskId)
        .select()
        .single();
    
    return Task.fromJson(response);
  }
}