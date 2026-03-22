import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'create_task_screen.dart';
import 'create_question_screen.dart';
import 'student_task_detail_screen.dart';

class TaskScreen extends ConsumerWidget {
  const TaskScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isInstructor = currentUser?.role.toLowerCase() == 'instructor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) return _buildEmptyState(isInstructor);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (_, index) {
              final task = tasks[index];
              return isInstructor
                  ? _InstructorTaskCard(task: task)
                  : _StudentTaskCard(task: task);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: isInstructor
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
              ),
              backgroundColor: lnuNavy,
              label: const Text('New Task / Quiz',
                  style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.assignment_add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isInstructor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.task_alt_rounded,
                size: 80, color: Colors.orange.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          const Text('No Active Tasks',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: lnuNavy)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isInstructor
                  ? 'Tap the button below to create your first task or quiz.'
                  : 'You have no pending assignments right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Instructor card — shows management actions ────────────────────────────────

class _InstructorTaskCard extends ConsumerWidget {
  final TaskModel task;
  const _InstructorTaskCard({required this.task});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPast = DateTime.now().isAfter(task.deadline);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + title + delete ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.red.withOpacity(0.08)
                        : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: isPast ? Colors.red : Colors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: lnuNavy)),
                      const SizedBox(height: 4),
                      Text(task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 22),
                  tooltip: 'Delete Task',
                  onPressed: () => _showDeleteDialog(context, task),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Meta row: score + deadline ───────────────────────────────────
            Row(
              children: [
                const Icon(Icons.score_outlined,
                    size: 15, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${task.maxScore} pts',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today,
                    size: 14,
                    color: isPast ? Colors.red : Colors.blueGrey),
                const SizedBox(width: 4),
                Text(
                  'Due: ${task.deadline.month}/${task.deadline.day}/${task.deadline.year}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isPast ? Colors.red : Colors.blueGrey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Action buttons ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateQuestionScreen(taskId: task.id),
                      ),
                    ),
                    icon: const Icon(Icons.quiz_outlined, size: 16),
                    label: const Text('Manage Questions',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: lnuNavy,
                      side: BorderSide(color: lnuNavy.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () =>
                        _showEditTaskSheet(context, ref, task),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Task',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskSheet(
      BuildContext context, WidgetRef ref, TaskModel task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    final scoreController =
        TextEditingController(text: task.maxScore.toString());
    DateTime selectedDate = task.deadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 28,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit Task',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: lnuNavy)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Instructions',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: scoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Max Points',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month,
                          color: lnuNavy, size: 16),
                      label: Text(
                        '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                        style: const TextStyle(color: lnuNavy),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: lnuNavy),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lnuNavy,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('tasks')
                        .doc(task.id)
                        .update({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'maxScore':
                          int.tryParse(scoreController.text) ?? task.maxScore,
                      'deadline': Timestamp.fromDate(selectedDate),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('SAVE CHANGES',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task',
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
            "Delete '${task.title}'? This will also remove all associated questions."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(task.id)
                  .delete();
              final questionSnap = await FirebaseFirestore.instance
                  .collection('questions')
                  .where('taskId', isEqualTo: task.id)
                  .get();
              for (final doc in questionSnap.docs) {
                await doc.reference.delete();
              }
            },
            child: const Text('DELETE',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Student card — shows deadline status + chevron ────────────────────────────

class _StudentTaskCard extends StatelessWidget {
  final TaskModel task;
  const _StudentTaskCard({required this.task});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context) {
    final isPast = DateTime.now().isAfter(task.deadline);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.red.shade50 : Colors.green.shade50,
          child: Icon(Icons.assignment_outlined,
              color: isPast ? Colors.red : Colors.green, size: 20),
        ),
        title: Text(task.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 12,
                    color: isPast ? Colors.red : Colors.blueGrey),
                const SizedBox(width: 4),
                Text(
                  'Due: ${task.deadline.month}/${task.deadline.day}/${task.deadline.year}',
                  style: TextStyle(
                      fontSize: 11,
                      color: isPast ? Colors.red : Colors.blueGrey,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.score_outlined,
                    size: 12, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Text('${task.maxScore} pts',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPast
                ? Colors.red.withOpacity(0.08)
                : Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isPast ? 'Overdue' : 'Open',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPast ? Colors.red : Colors.green),
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StudentTaskDetailScreen(task: task)),
        ),
      ),
    );
  }
}
