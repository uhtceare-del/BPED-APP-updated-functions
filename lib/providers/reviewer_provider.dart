import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reviewer_model.dart';
import '../repositories/reviewer_repository.dart';
import 'auth_provider.dart';

final reviewerRepositoryProvider = Provider<ReviewerRepository>((ref) {
  return ReviewerRepository(FirebaseFirestore.instance);
});

// Instructor view — only this instructor's uploaded reviewers.
// Students see all reviewers (shared study materials).
final allReviewersProvider = StreamProvider<List<ReviewerModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);

  if (user.role == 'instructor') {
    return ref
        .watch(reviewerRepositoryProvider)
        .getReviewersByInstructor(user.uid);
  }

  // Students see all reviewers from all instructors
  return ref.watch(reviewerRepositoryProvider).getAllReviewers();
});
