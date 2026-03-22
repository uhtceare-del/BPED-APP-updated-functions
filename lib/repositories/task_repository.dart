import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/question_model.dart';

class TaskRepository {
  final FirebaseFirestore firestore;
  TaskRepository(this.firestore);

  Stream<List<TaskModel>> getAllTasks() {
    return firestore
        .collection('tasks')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  /// Instructor: only tasks they created.
  Stream<List<TaskModel>> getTasksByInstructor(String instructorId) {
    return firestore
        .collection('tasks')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  /// Student: tasks scoped to their enrolled classes.
  /// Firestore whereIn supports up to 30 values; chunk accordingly.
  Stream<List<TaskModel>> getTasksByClassIds(List<String> classIds) {
    if (classIds.isEmpty) return Stream.value([]);

    // Build chunks of max 30
    final chunks = <List<String>>[];
    for (var i = 0; i < classIds.length; i += 30) {
      final end = (i + 30) > classIds.length ? classIds.length : (i + 30);
      chunks.add(classIds.sublist(i, end));
    }

    if (chunks.length == 1) {
      return firestore
          .collection('tasks')
          .where('classId', whereIn: chunks.first)
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
    }

    // Multiple chunks: fan out and merge
    final results = List<List<TaskModel>>.generate(chunks.length, (_) => []);
    return Stream.multi((controller) {
      for (var i = 0; i < chunks.length; i++) {
        final idx = i;
        firestore
            .collection('tasks')
            .where('classId', whereIn: chunks[idx])
            .snapshots()
            .map((snap) =>
                snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList())
            .listen((list) {
          results[idx] = list;
          controller.add(results.expand((e) => e).toList());
        });
      }
    });
  }

  Stream<List<TaskModel>> getTasksByLesson(String lessonId) {
    return firestore
        .collection('tasks')
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Future<String> createTask(TaskModel task) async {
    final doc = await firestore.collection('tasks').add({
      'title': task.title,
      'description': task.description,
      'maxScore': task.maxScore,
      'deadline': Timestamp.fromDate(task.deadline),
      'lessonId': task.lessonId,
      'instructorId': task.instructorId,
      'classId': task.classId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> addQuestion(QuestionModel question) async {
    await firestore.collection('questions').add(question.toMap());
  }

  Stream<List<QuestionModel>> getQuestionsByTask(String taskId) {
    return firestore
        .collection('questions')
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => QuestionModel.fromFirestore(doc)).toList());
  }

  Future<void> updateGrade(String submissionId, String grade) async {
    await firestore
        .collection('submissions')
        .doc(submissionId)
        .update({'grade': grade});
  }
}
