import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';

class LessonRepository {
  final FirebaseFirestore firestore;
  LessonRepository(this.firestore);

  Stream<List<LessonModel>> getAllLessons() {
    return firestore
        .collection('lessons')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  /// Instructor: only lessons they created.
  Stream<List<LessonModel>> getLessonsByInstructor(String instructorId) {
    return firestore
        .collection('lessons')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  /// Lessons for a specific course — used on course detail screen.
  Stream<List<LessonModel>> getLessonsByCourse(String courseId) {
    return firestore
        .collection('lessons')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  /// Student: lessons scoped to their enrolled classes.
  /// Uses Firestore whereIn chunked at 30 (same pattern as tasks).
  /// Lessons with no classId (old docs where classId == '') are included
  /// as a fallback so existing content is still visible.
  Stream<List<LessonModel>> getLessonsByClassIds(List<String> classIds) {
    if (classIds.isEmpty) return Stream.value([]);

    // Build chunks of max 30
    final chunks = <List<String>>[];
    for (var i = 0; i < classIds.length; i += 30) {
      final end = (i + 30) > classIds.length ? classIds.length : (i + 30);
      chunks.add(classIds.sublist(i, end));
    }

    if (chunks.length == 1) {
      return firestore
          .collection('lessons')
          .where('classId', whereIn: chunks.first)
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
    }

    // Multiple chunks: fan out and merge
    final results = List<List<LessonModel>>.generate(chunks.length, (_) => []);
    return Stream.multi((controller) {
      for (var i = 0; i < chunks.length; i++) {
        final idx = i;
        firestore
            .collection('lessons')
            .where('classId', whereIn: chunks[idx])
            .snapshots()
            .map((snap) => snap.docs
                .map((doc) => LessonModel.fromFirestore(doc))
                .toList())
            .listen((list) {
          results[idx] = list;
          controller.add(results.expand((e) => e).toList());
        });
      }
    });
  }

  Future<void> addLesson(LessonModel lesson) async {
    await firestore.collection('lessons').add(lesson.toMap());
  }

  Future<void> createLesson(LessonModel lesson) async {
    await firestore.collection('lessons').add(lesson.toMap());
  }
}
