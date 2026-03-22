import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedUsers() async {
  final firestore = FirebaseFirestore.instance;
  final classId = 'class_1_bped';

  for (int i = 1; i <= 50; i++) {
    await firestore.collection('users').add({
      'email': 'student$i@example.com',
      'role': 'student',
      'yearLevel': '1st Year',
      'classId': classId,
      'age': 18 + (i % 5),
      'avatarUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Instructor
  await firestore.collection('users').add({
    'email': 'professor@example.com',
    'role': 'instructor',
    'yearLevel': '',
    'classId': classId,
    'age': 35,
    'avatarUrl': '',
    'createdAt': FieldValue.serverTimestamp(),
  });
}