import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart';

class SubmissionRepository {
  final FirebaseFirestore firestore;
  SubmissionRepository(this.firestore);

  Stream<List<SubmissionModel>> getAllSubmissions() {
    return firestore.collection('submissions')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SubmissionModel.fromFirestore(doc))
        .toList());
  }
  Future<void> createSubmission(SubmissionModel submission) async {
    try {
      await firestore.collection('submissions').add(submission.toFirestore());
    } catch (e) {
      throw Exception("Failed to submit task: $e");
    }
  }
  Future<void> updateGrade(String submissionId, String grade) async {
    try {
      await firestore.collection('submissions').doc(submissionId).update({
        'grade': grade,
      });
    } catch (e) {
      throw Exception("Failed to update grade: $e");
    }
  }

  Stream<List<SubmissionModel>> getSubmissionsByTask(String taskId) {
    return firestore
        .collection('submissions')
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => SubmissionModel.fromFirestore(doc)).toList());
  }
  Stream<List<SubmissionModel>> getSubmissionsByStudent(String studentId) {
    return firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SubmissionModel.fromFirestore(doc))
        .toList());
  }
}