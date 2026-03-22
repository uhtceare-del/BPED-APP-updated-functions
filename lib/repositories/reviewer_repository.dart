import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reviewer_model.dart';

class ReviewerRepository {
  final FirebaseFirestore firestore;
  ReviewerRepository(this.firestore);

  // All reviewers — used by students (single-field orderBy is fine, no index needed)
  Stream<List<ReviewerModel>> getAllReviewers() {
    return firestore
        .collection('reviewers')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ReviewerModel.fromFirestore(doc)).toList());
  }

  // Only this instructor's reviewers.
  // We do NOT combine .where() + .orderBy() here — that requires a composite
  // index. Instead we sort in Dart after fetching, which works without any index.
  Stream<List<ReviewerModel>> getReviewersByInstructor(String instructorId) {
    return firestore
        .collection('reviewers')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ReviewerModel.fromFirestore(doc))
              .toList();
          // Sort newest first in Dart — no Firestore composite index needed
          list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return list;
        });
  }

  Future<void> uploadReviewer(ReviewerModel reviewer) async {
    await firestore.collection('reviewers').add(reviewer.toMap());
  }
}
