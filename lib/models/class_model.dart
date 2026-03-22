import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String className;   // e.g., BPED 2-B
  final String subject;     // e.g., Team Sports
  final String schedule;    // e.g., Mon/Wed 1:00PM - 2:30PM
  final List<String> enrolledStudentIds; // UIDs of enrolled students

  ClassModel({
    required this.id,
    required this.className,
    required this.subject,
    required this.schedule,
    this.enrolledStudentIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
      'schedule': schedule,
      'enrolledStudentIds': enrolledStudentIds,
    };
  }

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      className: data['className'] ?? '',
      subject: data['subject'] ?? '',
      schedule: data['schedule'] ?? '',
      enrolledStudentIds: List<String>.from(data['enrolledStudentIds'] ?? []),
    );
  }
}