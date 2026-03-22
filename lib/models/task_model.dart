import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final int maxScore;
  final DateTime deadline;
  final String? lessonId;
  final String instructorId;
  final String classId; // scopes this task to one class section

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.maxScore,
    required this.deadline,
    this.lessonId,
    this.instructorId = '',
    this.classId = '',
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedDeadline = DateTime.now();
    final rawDeadline = data['deadline'];
    if (rawDeadline is Timestamp) {
      parsedDeadline = rawDeadline.toDate();
    } else if (rawDeadline is String) {
      parsedDeadline = DateTime.tryParse(rawDeadline) ?? DateTime.now();
    }

    int parsedMaxScore = 100;
    final rawMaxScore = data['maxScore'];
    if (rawMaxScore is int) {
      parsedMaxScore = rawMaxScore;
    } else if (rawMaxScore != null) {
      parsedMaxScore = int.tryParse(rawMaxScore.toString()) ?? 100;
    }

    return TaskModel(
      id: doc.id,
      lessonId: data['lessonId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      maxScore: parsedMaxScore,
      deadline: parsedDeadline,
      instructorId: data['instructorId'] ?? '',
      classId: data['classId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'title': title,
      'description': description,
      'maxScore': maxScore,
      'deadline': Timestamp.fromDate(deadline),
      'instructorId': instructorId,
      'classId': classId,
    };
  }
}
