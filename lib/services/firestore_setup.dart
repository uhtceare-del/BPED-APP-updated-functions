import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSetup {
  final FirebaseFirestore firestore;

  FirestoreSetup(this.firestore);

  /// Initialize the BPED course structure
  Future<void> initialize() async {
    // 1. Create the main course
    final courseRef = firestore.collection('courses').doc('BPED');
    await courseRef.set({
      'name': 'Bachelor of Physical Education',
      'description': 'BPED Program',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Add year levels
    final yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
    for (var year in yearLevels) {
      final yearRef = courseRef.collection('yearLevels').doc(year);
      await yearRef.set({'name': year, 'createdAt': FieldValue.serverTimestamp()});

      // 3. Add a sample class for each year
      final classRef = yearRef.collection('classes').doc('Class A');
      await classRef.set({
        'name': 'Class A',
        'instructorId': null, // Assign later
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Add a sample lesson
      final lessonRef = classRef.collection('lessons').doc('Lesson 1');
      await lessonRef.set({
        'title': 'Introduction to Physical Education',
        'description': 'Overview of BPED Program',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Add a sample task (quiz/homework)
      final taskRef = lessonRef.collection('tasks').doc('Task 1');
      await taskRef.set({
        'title': 'Quiz: Basics of Physical Education',
        'description': 'Multiple choice quiz',
        'deadline': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 6. Add a sample reviewer (downloadable file)
      final reviewerRef = classRef.collection('reviewers').doc('Reviewer 1');
      await reviewerRef.set({
        'title': 'Introduction Notes',
        'url': '', // Upload later to Cloud Storage
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 7. Add a sample quiz
      final quizRef = lessonRef.collection('quizzes').doc('Quiz 1');
      await quizRef.set({
        'title': 'Quiz 1 - Basic Knowledge',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await quizRef.collection('questions').doc('Q1').set({
        'question': 'What is the main goal of Physical Education?',
        'options': ['Fitness', 'Fun', 'Health', 'All of the above'],
        'answer': 3, // index of correct answer
      });
    }

    print('Firestore setup complete!');
  }
}