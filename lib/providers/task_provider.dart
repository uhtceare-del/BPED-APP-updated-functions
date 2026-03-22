import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/question_model.dart';
import '../repositories/task_repository.dart';
import 'auth_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(firestoreProvider));
});

// ── Student's enrolled class IDs, live from Firestore ────────────────────────
final myClassIdsProvider = StreamProvider<List<String>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(authState.uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return <String>[];
    final data = snap.data() as Map<String, dynamic>;
    return List<String>.from(data['enrolledClassIds'] ?? []);
  });
});

// ── allTasksProvider ──────────────────────────────────────────────────────────
// Instructor → only tasks they created.
// Student    → only tasks whose classId is in the student's enrolled classes.
final allTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);

  if (user.role == 'instructor') {
    return ref.watch(taskRepositoryProvider).getTasksByInstructor(user.uid);
  }

  // Student path: wait for class IDs then scope query
  final classIdsAsync = ref.watch(myClassIdsProvider);
  final classIds = classIdsAsync.value ?? [];
  return ref.watch(taskRepositoryProvider).getTasksByClassIds(classIds);
});

// Tasks by lesson (lesson detail screen)
final tasksByLessonProvider =
    StreamProvider.family<List<TaskModel>, String>((ref, lessonId) {
  return ref.watch(taskRepositoryProvider).getTasksByLesson(lessonId);
});

// Quiz questions for a task
final questionsByTaskProvider =
    StreamProvider.family<List<QuestionModel>, String>((ref, taskId) {
  return ref.watch(taskRepositoryProvider).getQuestionsByTask(taskId);
});
