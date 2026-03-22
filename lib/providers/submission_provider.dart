import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart';
import '../repositories/submission_repository.dart';
import 'auth_provider.dart'; // To get the current user's ID

// 1. The Repository Provider
final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository(FirebaseFirestore.instance);
});

// 2. All Submissions (For Instructors)
final submissionProvider = StreamProvider<List<SubmissionModel>>((ref) {
  final repository = ref.watch(submissionRepositoryProvider);
  return repository.getAllSubmissions();
});

// 3. My Submissions (For Students)
final mySubmissionsProvider = StreamProvider<List<SubmissionModel>>((ref) {
  final repository = ref.watch(submissionRepositoryProvider);

  // Use watch to get the AsyncValue of the auth state
  final authState = ref.watch(authStateProvider);

  // We return the stream only if the user is data-ready and not null
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return repository.getSubmissionsByStudent(user.uid);
    },
    loading: () => Stream.value([]), // Return empty stream while loading
    error: (err, stack) => Stream.value([]), // Return empty stream on error
  );
});