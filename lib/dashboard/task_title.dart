import 'package:flutter/material.dart';
import '../dashboard/task_model.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final Function(bool) onStatusChanged;
  final VoidCallback onDelete;

  const TaskTile({
    Key? key,
    required this.task,
    required this.onStatusChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final primaryColor = theme.primaryColor;
    final surfaceColor = theme.cardColor;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          borderRadius: BorderRadius.circular(12),
          color:
              task.isCompleted
                  ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50)
                  : surfaceColor,
          elevation: task.isCompleted ? 0 : 2,
          shadowColor: primaryColor.withOpacity(0.1),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onStatusChanged(!task.isCompleted),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      task.isCompleted
                          ? Colors.transparent
                          : primaryColor.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        task.isCompleted
                            ? primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                    border: Border.all(
                      color:
                          task.isCompleted
                              ? primaryColor
                              : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child:
                        task.isCompleted
                            ? Icon(Icons.check, color: primaryColor, size: 20)
                            : const SizedBox(width: 20, height: 20),
                  ),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        task.isCompleted ? FontWeight.normal : FontWeight.w600,
                    decoration:
                        task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                    color:
                        task.isCompleted
                            ? isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600
                            : isDarkMode
                            ? Colors.white
                            : Colors.black87,
                    decorationColor: Colors.grey.shade500,
                    decorationThickness: 1.5,
                  ),
                ),
                subtitle: Text(
                  _formatDate(task.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDarkMode
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    task.isCompleted
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                        : const SizedBox(),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error.withOpacity(0.8),
                        ),
                        splashRadius: 24,
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
