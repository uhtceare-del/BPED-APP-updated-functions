import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewerModel {
  final String id;
  final String title;
  final String fileUrl;
  final String subject;      // renamed from 'category'; reads both keys for compat
  final String classId;      // scopes reviewer to one class section ('' for old docs)
  final DateTime uploadedAt;
  final String instructorId;

  // Convenience getter — UI code that still references .category continues to work
  String get category => subject;

  ReviewerModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.subject,
    this.classId = '',
    required this.uploadedAt,
    required this.instructorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'fileUrl': fileUrl,
      'subject': subject,               // always write as 'subject'
      'classId': classId,
      'instructorId': instructorId,
      'uploadedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ReviewerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Read 'subject' first; fall back to old 'category' for existing docs
    final subject = (data['subject'] as String?)?.isNotEmpty == true
        ? data['subject'] as String
        : (data['category'] as String?) ?? 'General';

    return ReviewerModel(
      id: doc.id,
      title: data['title'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      subject: subject,
      classId: data['classId'] ?? '',
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      instructorId: data['instructorId'] ?? '',
    );
  }
}
