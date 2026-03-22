import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String taskId;
  final String studentId;
  final String studentEmail;
  final DateTime submittedAt;
  final String? grade;
  final String? fileUrl;      // link to student's uploaded file (PDF/video)
  final String instructorId; // used by securedSubmissionsProvider to scope results

  SubmissionModel({
    required this.id,
    required this.taskId,
    required this.studentId,
    required this.studentEmail,
    required this.submittedAt,
    this.grade,
    this.fileUrl,
    this.instructorId = '',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'studentId': studentId,
      'studentEmail': studentEmail,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'grade': grade,
      'fileUrl': fileUrl,
      'instructorId': instructorId,
    };
  }

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SubmissionModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      grade: data['grade'],
      fileUrl: data['fileUrl'],
      instructorId: data['instructorId'] ?? '',
    );
  }
}
