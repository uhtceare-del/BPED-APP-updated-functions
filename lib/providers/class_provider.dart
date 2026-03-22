import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../repositories/class_repository.dart';
import 'auth_provider.dart';

// 1. Repository Provider
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository(FirebaseFirestore.instance);
});

// 2. All classes — for instructor view
final allClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  return ref.watch(classRepositoryProvider).getClasses();
});

// 3. Classes for the current student
final myClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);
  return ref.watch(classRepositoryProvider).getClassesForStudent(user.uid);
});

// 4. Students in a specific class — used in the instructor's class detail view
final studentsInClassProvider =
FutureProvider.family<List<AppUser>, String>((ref, classId) {
  return ref.watch(classRepositoryProvider).getStudentsInClass(classId);
});