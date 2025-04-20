import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task/app/theme_provider.dart';
import 'package:task/dashboard/task_title.dart';
import 'package:task/service/supabase_service.dart';
import '../auth/auth_service.dart';
import '../dashboard/task_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _taskController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _showCompletedTasks = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _loadTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthService>().user?.id;

      if (userId == null) {
        throw Exception("User ID is not available. Please log in again.");
      }

      final tasks = await _supabaseService.getTasks();

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error loading tasks: ${e.toString()}');
      }
    }
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    Navigator.pop(context);

    final loadingSnackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Text(
            'Adding task...',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      duration: const Duration(seconds: 1),
    );

    ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

    try {
      final userId = context.read<AuthService>().user?.id;
      if (userId == null) {
        throw Exception("User ID is not available. Please log in again.");
      }

      final task = await _supabaseService.createTask(
        _taskController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _tasks.insert(0, task);
        });
        _taskController.clear();

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add task: ${e.toString()}');
    }
  }

  Future<void> _deleteTask(String taskId) async {
    // Optimistic update
    final deletedTaskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (deletedTaskIndex == -1) return;

    final deletedTask = _tasks[deletedTaskIndex];

    setState(() {
      _tasks.removeWhere((task) => task.id == taskId);
    });

    try {
      await _supabaseService.deleteTask(taskId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                final userId = context.read<AuthService>().user?.id;
                if (userId == null) {
                  throw Exception("User ID is not available");
                }

                final task = await _supabaseService.createTask(
                  deletedTask.title,
                );
                setState(() {
                  _tasks.insert(deletedTaskIndex, task);
                });
              } catch (e) {
                _showErrorSnackBar('Failed to restore task: ${e.toString()}');
              }
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _tasks.insert(deletedTaskIndex, deletedTask);
      });
      _showErrorSnackBar('Failed to delete task: ${e.toString()}');
    }
  }

  Future<void> _updateTaskStatus(String taskId, bool isCompleted) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;

    final oldTask = _tasks[index];

    setState(() {
      _tasks[index] = Task(
        id: oldTask.id,
        title: oldTask.title,
        isCompleted: isCompleted,
        createdAt: oldTask.createdAt,
        userId: oldTask.userId,
      );
    });

    try {
      final updatedTask = await _supabaseService.updateTaskStatus(
        taskId,
        isCompleted,
      );

      if (mounted) {
        setState(() {
          _tasks[index] = updatedTask;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tasks[index] = oldTask;
        });
        _showErrorSnackBar('Failed to update task: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<AuthService>().user;

    final themeProvider = Provider.of<ThemeProvider>(context);

    final filteredTasks =
        _showCompletedTasks
            ? _tasks
            : _tasks.where((task) => !task.isCompleted).toList();

    return Scaffold(
      backgroundColor:
          theme.brightness == Brightness.light
              ? Colors.grey.shade100
              : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.checklist_rounded, color: theme.primaryColor, size: 28),
            const SizedBox(width: 8),
            Text(
              'TaskHub',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: 'Switch theme',
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh tasks',
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await context.read<AuthService>().signOut();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 8.0,
                        ),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'userAvatar',
                              child: Material(
                                elevation: 4,
                                shadowColor: theme.primaryColor.withOpacity(
                                  0.4,
                                ),
                                shape: const CircleBorder(),
                                child: CircleAvatar(
                                  backgroundColor: theme.primaryColor,
                                  radius: 24,
                                  child: Text(
                                    user?.email
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back!',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user?.email ?? 'User',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_tasks.isNotEmpty) _buildTaskCounter(),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Tasks',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${filteredTasks.length} tasks',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            filteredTasks.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No tasks to display',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                                : AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: filteredTasks.length,
                                      itemBuilder: (context, index) {
                                        final task = filteredTasks[index];
                                        final animationDelay = index * 0.05;
                                        final itemAnimation = Tween<double>(
                                          begin: 0.0,
                                          end: 1.0,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: _animationController,
                                            curve: Interval(
                                              animationDelay.clamp(0.0, 0.9),
                                              (animationDelay + 0.1).clamp(
                                                0.0,
                                                1.0,
                                              ),
                                              curve: Curves.easeOut,
                                            ),
                                          ),
                                        );

                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            50 * (1 - itemAnimation.value),
                                          ),
                                          child: Opacity(
                                            opacity: itemAnimation.value,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: TaskTile(
                                                task: task,
                                                onStatusChanged:
                                                    (isCompleted) =>
                                                        _updateTaskStatus(
                                                          task.id,
                                                          isCompleted,
                                                        ),
                                                onDelete:
                                                    () => _deleteTask(task.id),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
      floatingActionButton:
          _tasks.isEmpty
              ? null
              : FloatingActionButton.extended(
                onPressed: _showAddTaskBottomSheet,
                icon: const Icon(Icons.add),
                label: const Text('New Task'),
                elevation: 4,
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Include the missing methods
  void _showAddTaskBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        'Add New Task',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    labelText: 'Task Name',
                    hintText: 'Enter your task',
                    prefixIcon: const Icon(Icons.task_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  onFieldSubmitted: (_) => _addTask(),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add_task),
                  label: const Text('ADD TASK'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'All Caught Up!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your first task to get started',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showAddTaskBottomSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('ADD TASK'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCounter() {
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final progress = _tasks.isEmpty ? 0.0 : completedTasks / _tasks.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      strokeWidth: 6,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedTasks of ${_tasks.length} tasks completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
