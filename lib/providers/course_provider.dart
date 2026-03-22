import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../repositories/course_repository.dart';
import 'auth_provider.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(FirebaseFirestore.instance);
});

// All courses — students browse this to self-enroll.
// Instructors no longer manage courses; this is admin territory.
final allCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  return ref.watch(courseRepositoryProvider).getAllCourses();
});

// Student's enrolled courses only — used on the enrolled tab.
final enrolledCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);
  return ref.watch(courseRepositoryProvider).getEnrolledCourses(user.uid);
});

// Selected course (navigation helper)
final selectedCourseProvider = StateProvider<CourseModel?>((ref) => null);
