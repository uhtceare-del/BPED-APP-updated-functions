import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';

class ClassRepository {
  final FirebaseFirestore _firestore;
  ClassRepository(this._firestore);

  // Stream all classes
  Stream<List<ClassModel>> getClasses() {
    return _firestore
        .collection('classes')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList());
  }

  // Create a new class section
  Future<void> createClass(ClassModel classData) async {
    await _firestore.collection('classes').add(classData.toMap());
  }

  // Enroll a student into a class
  Future<void> enrollStudent({
    required String classId,
    required String studentId,
  }) async {
    await _firestore.collection('classes').doc(classId).update({
      'enrolledStudentIds': FieldValue.arrayUnion([studentId]),
    });
    // Also write classId onto the student's document for reverse lookup
    await _firestore.collection('users').doc(studentId).update({
      'enrolledClassIds': FieldValue.arrayUnion([classId]),
    });
  }

  // Remove a student from a class
  Future<void> unenrollStudent({
    required String classId,
    required String studentId,
  }) async {
    await _firestore.collection('classes').doc(classId).update({
      'enrolledStudentIds': FieldValue.arrayRemove([studentId]),
    });
    await _firestore.collection('users').doc(studentId).update({
      'enrolledClassIds': FieldValue.arrayRemove([classId]),
    });
  }

  // Fetch all AppUser objects who are enrolled in a given class
  Future<List<AppUser>> getStudentsInClass(String classId) async {
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    final data = classDoc.data();
    if (data == null) return [];

    final ids = List<String>.from(data['enrolledStudentIds'] ?? []);
    if (ids.isEmpty) return [];

    // Firestore whereIn limit is 10 — chunk if needed
    final List<AppUser> students = [];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snap = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      students.addAll(
          snap.docs.map((d) => AppUser.fromFirestore(d.data(), d.id)));
    }
    return students;
  }

  // Classes that a specific student belongs to
  Stream<List<ClassModel>> getClassesForStudent(String studentId) {
    return _firestore
        .collection('classes')
        .where('enrolledStudentIds', arrayContains: studentId)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => ClassModel.fromFirestore(doc)).toList());
  }
}