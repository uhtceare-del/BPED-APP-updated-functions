import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String courseId;
  final String classId;      // scopes lesson to one class section ('' for old docs)
  final String title;
  final String description;
  final String? videoUrl;
  final String? pdfUrl;
  final String? audioUrl;
  final String? subject;     // renamed from 'category'; reads both keys for compat
  final String? category;    // kept read-only for backward compat display
  final String instructorId;

  LessonModel({
    required this.id,
    required this.courseId,
    this.classId = '',
    required this.title,
    required this.description,
    this.videoUrl,
    this.pdfUrl,
    this.audioUrl,
    this.subject,
    this.category,
    this.instructorId = '',
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map<String, dynamic>) {
      return LessonModel(
          id: doc.id, courseId: '', title: '', description: '');
    }

    // Read 'subject' first; fall back to old 'category' field for existing docs
    final subject = (data['subject'] as String?)?.isNotEmpty == true
        ? data['subject'] as String
        : data['category'] as String?;

    return LessonModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      classId: data['classId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'],
      pdfUrl: data['pdfUrl'],
      audioUrl: data['audioUrl'],
      subject: subject,
      category: data['category'] ?? '',   // kept for any existing read-path
      instructorId: data['instructorId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'classId': classId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'pdfUrl': pdfUrl,
      'audioUrl': audioUrl,
      'subject': subject ?? '',           // always write as 'subject'
      'instructorId': instructorId,
    };
  }
}
