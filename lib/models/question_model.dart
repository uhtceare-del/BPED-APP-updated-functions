import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String taskId; // Links this question to a specific Task/Quiz
  final String questionText;
  final List<String> choices;
  final int correctAnswerIndex;

  QuestionModel({
    required this.id,
    required this.taskId,
    required this.questionText,
    required this.choices,
    required this.correctAnswerIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'questionText': questionText,
      'choices': choices,
      'correctAnswerIndex': correctAnswerIndex,
    };
  }

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      questionText: data['questionText'] ?? '',
      choices: List<String>.from(data['choices'] ?? []),
      correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
    );
  }
}