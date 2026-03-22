import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class CourseRepository {
  final FirebaseFirestore firestore;
  CourseRepository(this.firestore);

  /// All courses — used by students to browse and by admin to manage.
  Stream<List<CourseModel>> getAllCourses() {
    return firestore.collection('courses').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList());
  }

  /// Courses a student is enrolled in.
  Stream<List<CourseModel>> getEnrolledCourses(String studentId) {
    return firestore
        .collection('courses')
        .where('enrolledStudents', arrayContains: studentId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList());
  }

  /// Student self-enrolls into a course.
  Future<void> enrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    final batch = firestore.batch();

    // Add studentId to course.enrolledStudents
    final courseRef = firestore.collection('courses').doc(courseId);
    batch.update(courseRef, {
      'enrolledStudents': FieldValue.arrayUnion([studentId]),
    });

    // Add courseId to user.enrolledCourses for reverse lookup
    final userRef = firestore.collection('users').doc(studentId);
    batch.update(userRef, {
      'enrolledCourses': FieldValue.arrayUnion([courseId]),
    });

    await batch.commit();
  }

  /// Student unenrolls from a course.
  Future<void> unenrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    final batch = firestore.batch();

    final courseRef = firestore.collection('courses').doc(courseId);
    batch.update(courseRef, {
      'enrolledStudents': FieldValue.arrayRemove([studentId]),
    });

    final userRef = firestore.collection('users').doc(studentId);
    batch.update(userRef, {
      'enrolledCourses': FieldValue.arrayRemove([courseId]),
    });

    await batch.commit();
  }

  /// Admin: create a new course.
  Future<void> createCourse(CourseModel course) async {
    await firestore.collection('courses').add(course.toMap());
  }

  /// Admin: update a course.
  Future<void> updateCourse(String courseId, Map<String, dynamic> data) async {
    await firestore.collection('courses').doc(courseId).update(data);
  }

  /// Admin: delete a course.
  Future<void> deleteCourse(String courseId) async {
    await firestore.collection('courses').doc(courseId).delete();
  }

  Future<List<CourseModel>> getAllCoursesOnce() async {
    final snapshot = await firestore.collection('courses').get();
    return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
  }
}
