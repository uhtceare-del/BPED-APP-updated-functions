import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String name;
  final String description;
  // instructorId removed — courses are created/managed by admin only.
  // The field is kept optional so existing Firestore docs don't break.
  final String? instructorId;
  final String? videoUrl;
  final List<String> enrolledStudents;

  CourseModel({
    required this.id,
    required this.name,
    required this.description,
    this.instructorId,
    this.videoUrl,
    this.enrolledStudents = const [],
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      instructorId: data['instructorId'],
      videoUrl: data['videoUrl'],
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      if (instructorId != null) 'instructorId': instructorId,
      'videoUrl': videoUrl,
      'enrolledStudents': enrolledStudents,
    };
  }
}
