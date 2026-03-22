// student_provider.dart
//
// NOTE: enrolledCoursesProvider lives in course_provider.dart — do NOT
// redefine it here. This file only holds student-specific derived data.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'auth_provider.dart';

// Student tasks filtered to only those not yet past deadline.
// Used by the student dashboard task tab.
final studentTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  final now = Timestamp.now();

  return ref.watch(firestoreProvider)
      .collection('tasks')
      .where('deadline', isGreaterThanOrEqualTo: now)
      .orderBy('deadline')
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => TaskModel.fromFirestore(doc))
      .toList());
});