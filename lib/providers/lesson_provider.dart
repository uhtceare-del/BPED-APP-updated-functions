import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/lesson_repository.dart';
import '../models/lesson_model.dart';
import 'auth_provider.dart';
import 'task_provider.dart'; // for myClassIdsProvider

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(ref.watch(firestoreProvider));
});

// ── allLessonsProvider ────────────────────────────────────────────────────────
// Instructor → only lessons they created (scoped by instructorId).
// Student    → lessons whose classId is in the student's enrolled classes.
//              Falls back to showing all lessons if student has no classIds yet
//              (e.g. new account still in onboarding), so the screen isn't blank.
final allLessonsProvider = StreamProvider<List<LessonModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);

  if (user.role == 'instructor') {
    return ref
        .watch(lessonRepositoryProvider)
        .getLessonsByInstructor(user.uid);
  }

  // Student path: wait for class IDs then scope query
  final classIdsAsync = ref.watch(myClassIdsProvider);
  final classIds = classIdsAsync.value ?? [];

  if (classIds.isEmpty) {
    // Student enrolled in no classes yet — show nothing
    return Stream.value([]);
  }

  return ref
      .watch(lessonRepositoryProvider)
      .getLessonsByClassIds(classIds);
});

// Lessons by course — used on course detail screen (both roles)
final lessonsByCourseProvider =
    StreamProvider.family<List<LessonModel>, String>((ref, courseId) {
  return ref.watch(lessonRepositoryProvider).getLessonsByCourse(courseId);
});
