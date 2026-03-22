// test/app_test.dart
//
// Run with:  flutter test
//
// Required dev dependencies in pubspec.yaml:
//
//   dev_dependencies:
//     flutter_test:
//       sdk: flutter
//     flutter_lints: ^6.0.0
//     hive_generator: ^2.0.1
//     build_runner: ^2.4.8
//     fake_cloud_firestore: ^3.0.3   ← add this
//     mockito: ^5.4.4                ← add this
//     build_runner: ^2.4.8

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:phys_ed/models/task_model.dart';
import 'package:phys_ed/models/question_model.dart';
import 'package:phys_ed/models/submission_model.dart';
import 'package:phys_ed/models/course_model.dart';
import 'package:phys_ed/models/class_model.dart';
import 'package:phys_ed/models/lesson_model.dart';
import 'package:phys_ed/models/reviewer_model.dart';
import 'package:phys_ed/models/user_model.dart';

import 'package:phys_ed/repositories/task_repository.dart';
import 'package:phys_ed/repositories/submission_repository.dart';
import 'package:phys_ed/repositories/course_repository.dart';
import 'package:phys_ed/repositories/class_repository.dart';
import 'package:phys_ed/repositories/reviewer_repository.dart';
import 'package:phys_ed/repositories/lesson_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a fake Firestore DocumentSnapshot for a given collection/id/data.
Future<DocumentSnapshot> fakeDoc(
  FakeFirebaseFirestore db,
  String collection,
  String id,
  Map<String, dynamic> data,
) async {
  await db.collection(collection).doc(id).set(data);
  return db.collection(collection).doc(id).get();
}

/// Calculates quiz score exactly as TakeQuizScreen does.
String calculateQuizGrade({
  required List<QuestionModel> questions,
  required Map<String, int> selectedAnswers,
  required int maxScore,
}) {
  int correct = 0;
  for (final q in questions) {
    if (selectedAnswers[q.id] == q.correctAnswerIndex) correct++;
  }
  final raw = (correct / questions.length) * maxScore;
  return raw.round().toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. MODEL TESTS
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── 1a. TaskModel ──────────────────────────────────────────────────────────
  group('TaskModel', () {
    late FakeFirebaseFirestore db;

    setUp(() => db = FakeFirebaseFirestore());

    test('fromFirestore maps all fields correctly', () async {
      final deadline = DateTime(2025, 12, 31);
      final doc = await fakeDoc(db, 'tasks', 'task1', {
        'title': 'Midterm Quiz',
        'description': 'Cover chapters 1–5',
        'maxScore': 100,
        'deadline': Timestamp.fromDate(deadline),
        'lessonId': 'lesson_abc',
        'instructorId': 'inst_001',
        'classId': 'class_bped2b',
      });

      final task = TaskModel.fromFirestore(doc);

      expect(task.id, 'task1');
      expect(task.title, 'Midterm Quiz');
      expect(task.description, 'Cover chapters 1–5');
      expect(task.maxScore, 100);
      expect(task.deadline, deadline);
      expect(task.lessonId, 'lesson_abc');
      expect(task.instructorId, 'inst_001');
      expect(task.classId, 'class_bped2b');
    });

    test('fromFirestore handles missing optional fields with safe defaults',
        () async {
      final doc = await fakeDoc(db, 'tasks', 'task2', {
        'title': 'PE Assignment',
        'description': '',
        'deadline': Timestamp.fromDate(DateTime.now()),
      });

      final task = TaskModel.fromFirestore(doc);

      expect(task.maxScore, 100); // default
      expect(task.instructorId, ''); // default
      expect(task.classId, ''); // default
      expect(task.lessonId, ''); // default
    });

    test('fromFirestore parses maxScore from String', () async {
      final doc = await fakeDoc(db, 'tasks', 'task3', {
        'title': 'Test',
        'description': '',
        'maxScore': '75', // stored as String — legacy data
        'deadline': Timestamp.fromDate(DateTime.now()),
      });

      final task = TaskModel.fromFirestore(doc);
      expect(task.maxScore, 75);
    });

    test('toMap serializes all fields', () {
      final deadline = DateTime(2025, 6, 15);
      final task = TaskModel(
        id: '',
        title: 'Basketball Drill',
        description: 'Perform 3 layup drills',
        maxScore: 50,
        deadline: deadline,
        lessonId: 'les_001',
        instructorId: 'inst_abc',
        classId: 'cls_xyz',
      );

      final map = task.toMap();
      expect(map['title'], 'Basketball Drill');
      expect(map['maxScore'], 50);
      expect(map['instructorId'], 'inst_abc');
      expect(map['classId'], 'cls_xyz');
      expect(map['deadline'], isA<Timestamp>());
    });
  });

  // ── 1b. QuestionModel ──────────────────────────────────────────────────────
  group('QuestionModel', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('fromFirestore maps all fields', () async {
      final doc = await fakeDoc(db, 'questions', 'q1', {
        'taskId': 'task_abc',
        'questionText': 'What is the capital of the Philippines?',
        'choices': ['Cebu', 'Manila', 'Davao', 'Iloilo'],
        'correctAnswerIndex': 1,
      });

      final q = QuestionModel.fromFirestore(doc);
      expect(q.id, 'q1');
      expect(q.taskId, 'task_abc');
      expect(q.questionText, 'What is the capital of the Philippines?');
      expect(q.choices.length, 4);
      expect(q.correctAnswerIndex, 1);
    });

    test('toMap serializes correctly', () {
      final q = QuestionModel(
        id: '',
        taskId: 'task_001',
        questionText: 'Name a team sport.',
        choices: ['Basketball', 'Swimming', 'Archery'],
        correctAnswerIndex: 0,
      );

      final map = q.toMap();
      expect(map['taskId'], 'task_001');
      expect(map['choices'], ['Basketball', 'Swimming', 'Archery']);
      expect(map['correctAnswerIndex'], 0);
    });
  });

  // ── 1c. SubmissionModel ────────────────────────────────────────────────────
  group('SubmissionModel', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('fromFirestore maps all fields including optional grade', () async {
      final submittedAt = DateTime(2025, 10, 1, 9, 0);
      final doc = await fakeDoc(db, 'submissions', 'sub1', {
        'taskId': 'task_abc',
        'studentId': 'stu_001',
        'studentEmail': 'student@gmail.com',
        'submittedAt': Timestamp.fromDate(submittedAt),
        'grade': '88',
        'fileUrl': 'https://cloudinary.com/file.pdf',
        'instructorId': 'inst_001',
      });

      final sub = SubmissionModel.fromFirestore(doc);
      expect(sub.id, 'sub1');
      expect(sub.taskId, 'task_abc');
      expect(sub.studentId, 'stu_001');
      expect(sub.grade, '88');
      expect(sub.fileUrl, 'https://cloudinary.com/file.pdf');
      expect(sub.instructorId, 'inst_001');
    });

    test('fromFirestore handles null grade gracefully', () async {
      final doc = await fakeDoc(db, 'submissions', 'sub2', {
        'taskId': 'task_xyz',
        'studentId': 'stu_002',
        'studentEmail': 'other@gmail.com',
        'submittedAt': Timestamp.fromDate(DateTime.now()),
      });

      final sub = SubmissionModel.fromFirestore(doc);
      expect(sub.grade, isNull);
      expect(sub.fileUrl, isNull);
    });

    test('toFirestore serializes correctly', () {
      final now = DateTime(2025, 11, 5);
      final sub = SubmissionModel(
        id: '',
        taskId: 'task_001',
        studentId: 'stu_001',
        studentEmail: 'stu@gmail.com',
        submittedAt: now,
        grade: '95',
        fileUrl: null,
        instructorId: 'inst_abc',
      );

      final map = sub.toFirestore();
      expect(map['taskId'], 'task_001');
      expect(map['grade'], '95');
      expect(map['instructorId'], 'inst_abc');
      expect(map['submittedAt'], isA<Timestamp>());
    });
  });

  // ── 1d. CourseModel ────────────────────────────────────────────────────────
  group('CourseModel', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('fromFirestore maps fields including enrolled students', () async {
      final doc = await fakeDoc(db, 'courses', 'crs1', {
        'name': 'Team Sports',
        'description': 'Introduction to team sports',
        'enrolledStudents': ['stu_1', 'stu_2', 'stu_3'],
      });

      final course = CourseModel.fromFirestore(doc);
      expect(course.name, 'Team Sports');
      expect(course.enrolledStudents, hasLength(3));
      expect(course.enrolledStudents, contains('stu_2'));
    });

    test('fromFirestore defaults to empty enrolled list', () async {
      final doc = await fakeDoc(db, 'courses', 'crs2', {
        'name': 'Gymnastics',
        'description': 'Basic gymnastics',
      });

      final course = CourseModel.fromFirestore(doc);
      expect(course.enrolledStudents, isEmpty);
    });
  });

  // ── 1e. ClassModel ─────────────────────────────────────────────────────────
  group('ClassModel', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('fromFirestore maps class fields', () async {
      final doc = await fakeDoc(db, 'classes', 'cls1', {
        'className': 'BPED 2-B',
        'subject': 'Team Sports',
        'schedule': 'Mon/Wed 1:00PM–2:30PM',
        'enrolledStudentIds': ['s1', 's2'],
      });

      final cls = ClassModel.fromFirestore(doc);
      expect(cls.id, 'cls1');
      expect(cls.className, 'BPED 2-B');
      expect(cls.enrolledStudentIds, hasLength(2));
    });

    test('toMap serializes correctly', () {
      final cls = ClassModel(
        id: '',
        className: 'BPED 3-A',
        subject: 'Individual Sports',
        schedule: 'Tue/Thu 8:00AM',
        enrolledStudentIds: ['s1', 's2', 's3'],
      );

      final map = cls.toMap();
      expect(map['className'], 'BPED 3-A');
      expect(map['enrolledStudentIds'], hasLength(3));
    });
  });

  // ── 1f. LessonModel ────────────────────────────────────────────────────────
  group('LessonModel', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('fromFirestore maps all media fields', () async {
      final doc = await fakeDoc(db, 'lessons', 'les1', {
        'courseId': 'crs_001',
        'title': 'Kinesiology Basics',
        'description': 'Introduction to human movement',
        'videoUrl': 'https://cloudinary.com/video.mp4',
        'pdfUrl': 'https://cloudinary.com/doc.pdf',
        'audioUrl': 'https://cloudinary.com/audio.mp3',
        'category': 'Kinesiology',
        'instructorId': 'inst_001',
      });

      final lesson = LessonModel.fromFirestore(doc);
      expect(lesson.title, 'Kinesiology Basics');
      expect(lesson.videoUrl, contains('video.mp4'));
      expect(lesson.pdfUrl, contains('doc.pdf'));
      expect(lesson.audioUrl, contains('audio.mp3'));
      expect(lesson.category, 'Kinesiology');
    });

    test('fromFirestore handles null media fields', () async {
      final doc = await fakeDoc(db, 'lessons', 'les2', {
        'courseId': 'crs_002',
        'title': 'Text Only Lesson',
        'description': 'No media attached',
      });

      final lesson = LessonModel.fromFirestore(doc);
      expect(lesson.videoUrl, isNull);
      expect(lesson.pdfUrl, isNull);
      expect(lesson.audioUrl, isNull);
    });
  });

  // ── 1g. ReviewerModel ──────────────────────────────────────────────────────
  group('ReviewerModel', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('fromFirestore maps all fields', () async {
      final uploadedAt = DateTime(2025, 9, 1);
      final doc = await fakeDoc(db, 'reviewers', 'rev1', {
        'title': 'Anatomy Reviewer',
        'fileUrl': 'https://cloudinary.com/reviewer.pdf',
        'category': 'Anatomy',
        'instructorId': 'inst_001',
        'uploadedAt': Timestamp.fromDate(uploadedAt),
      });

      final rev = ReviewerModel.fromFirestore(doc);
      expect(rev.title, 'Anatomy Reviewer');
      expect(rev.category, 'Anatomy');
      expect(rev.instructorId, 'inst_001');
    });

    test('fromFirestore defaults category to General', () async {
      final doc = await fakeDoc(db, 'reviewers', 'rev2', {
        'title': 'General Reviewer',
        'fileUrl': 'https://cloudinary.com/gen.pdf',
        'instructorId': 'inst_002',
        'uploadedAt': Timestamp.fromDate(DateTime.now()),
      });

      final rev = ReviewerModel.fromFirestore(doc);
      expect(rev.category, 'General');
    });
  });

  // ── 1h. AppUser ────────────────────────────────────────────────────────────
  group('AppUser', () {
    test('fromFirestore maps student fields', () {
      final data = {
        'email': 'student@gmail.com',
        'fullName': 'Juan Dela Cruz',
        'role': 'student',
        'avatarUrl': '',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'section': 'PE-21',
        'yearLevel': '2',
        'onboardingCompleted': true,
      };

      final user = AppUser.fromFirestore(data, 'uid_001');
      expect(user.uid, 'uid_001');
      expect(user.fullName, 'Juan Dela Cruz');
      expect(user.role, 'student');
      expect(user.section, 'PE-21');
      expect(user.yearLevel, '2');
      expect(user.onboardingCompleted, isTrue);
    });

    test('fromFirestore maps instructor fields (no section/yearLevel)', () {
      final data = {
        'email': 'instructor@gmail.com',
        'fullName': 'Prof. Santos',
        'role': 'instructor',
        'avatarUrl': 'https://cloudinary.com/avatar.jpg',
        'createdAt': Timestamp.fromDate(DateTime(2023, 6, 1)),
        'onboardingCompleted': true,
      };

      final user = AppUser.fromFirestore(data, 'inst_001');
      expect(user.role, 'instructor');
      expect(user.section, isNull);
      expect(user.yearLevel, isNull);
    });

    test('fromFirestore converts integer yearLevel to String', () {
      final data = {
        'email': 'old@gmail.com',
        'role': 'student',
        'avatarUrl': '',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'yearLevel': 3, // stored as int in legacy data
        'onboardingCompleted': true,
      };

      final user = AppUser.fromFirestore(data, 'uid_legacy');
      expect(user.yearLevel, '3'); // must be a String
    });

    test('toFirestore round-trips cleanly', () {
      final user = AppUser(
        uid: 'u1',
        email: 'test@gmail.com',
        fullName: 'Test User',
        role: 'student',
        avatarUrl: '',
        createdAt: DateTime(2025, 1, 1),
        section: 'PE-11',
        yearLevel: '1',
        onboardingCompleted: true,
      );

      final map = user.toFirestore();
      expect(map['email'], 'test@gmail.com');
      expect(map['role'], 'student');
      expect(map['section'], 'PE-11');
      expect(map['onboardingCompleted'], isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. BUSINESS LOGIC TESTS
  // ─────────────────────────────────────────────────────────────────────────

  group('Quiz grading logic', () {
    final questions = [
      QuestionModel(
          id: 'q1',
          taskId: 't1',
          questionText: 'Q1',
          choices: ['A', 'B', 'C'],
          correctAnswerIndex: 0),
      QuestionModel(
          id: 'q2',
          taskId: 't1',
          questionText: 'Q2',
          choices: ['A', 'B', 'C'],
          correctAnswerIndex: 2),
      QuestionModel(
          id: 'q3',
          taskId: 't1',
          questionText: 'Q3',
          choices: ['A', 'B', 'C'],
          correctAnswerIndex: 1),
      QuestionModel(
          id: 'q4',
          taskId: 't1',
          questionText: 'Q4',
          choices: ['A', 'B', 'C'],
          correctAnswerIndex: 0),
    ];

    test('perfect score returns maxScore', () {
      final answers = {'q1': 0, 'q2': 2, 'q3': 1, 'q4': 0};
      expect(
        calculateQuizGrade(
            questions: questions, selectedAnswers: answers, maxScore: 100),
        '100',
      );
    });

    test('zero correct returns 0', () {
      final answers = {'q1': 1, 'q2': 0, 'q3': 0, 'q4': 1};
      expect(
        calculateQuizGrade(
            questions: questions, selectedAnswers: answers, maxScore: 100),
        '0',
      );
    });

    test('half correct returns 50 out of 100', () {
      // q1 correct (0), q2 correct (2), q3 wrong (2), q4 wrong (1)
      final answers = {'q1': 0, 'q2': 2, 'q3': 2, 'q4': 1};
      expect(
        calculateQuizGrade(
            questions: questions, selectedAnswers: answers, maxScore: 100),
        '50',
      );
    });

    test('score is proportional to maxScore', () {
      // 3 out of 4 correct = 75%
      final answers = {'q1': 0, 'q2': 2, 'q3': 1, 'q4': 1}; // q4 wrong
      expect(
        calculateQuizGrade(
            questions: questions, selectedAnswers: answers, maxScore: 50),
        '38', // (3/4) * 50 = 37.5 → rounds to 38
      );
    });

    test('rounds correctly for non-integer scores', () {
      // 1 out of 3 questions, maxScore = 10 → 3.33 → rounds to 3
      final threeQs = questions.sublist(0, 3);
      final answers = {'q1': 0, 'q2': 0, 'q3': 0}; // only q1 correct
      expect(
        calculateQuizGrade(
            questions: threeQs, selectedAnswers: answers, maxScore: 10),
        '3',
      );
    });
  });

  group('Deadline logic', () {
    test('task with past deadline is overdue', () {
      final task = TaskModel(
        id: 't1',
        title: 'Old Task',
        description: '',
        maxScore: 100,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(DateTime.now().isAfter(task.deadline), isTrue);
    });

    test('task with future deadline is still open', () {
      final task = TaskModel(
        id: 't2',
        title: 'Future Task',
        description: '',
        maxScore: 100,
        deadline: DateTime.now().add(const Duration(days: 7)),
      );
      expect(DateTime.now().isAfter(task.deadline), isFalse);
    });

    test('task due exactly now is not overdue (boundary)', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 't3',
        title: 'Boundary Task',
        description: '',
        maxScore: 100,
        deadline: now.add(const Duration(seconds: 5)),
      );
      expect(DateTime.now().isAfter(task.deadline), isFalse);
    });
  });

  group('Enrollment logic', () {
    test('student is enrolled when uid is in enrolledStudents', () {
      final course = CourseModel(
        id: 'c1',
        name: 'Team Sports',
        description: '',
        enrolledStudents: ['stu_001', 'stu_002'],
      );
      expect(course.enrolledStudents.contains('stu_001'), isTrue);
      expect(course.enrolledStudents.contains('stu_999'), isFalse);
    });

    test('student class isolation — task classId must match enrolled class', () {
      const enrolledClassIds = ['cls_a', 'cls_b'];

      final taskInClass = TaskModel(
        id: 't1',
        title: 'Task A',
        description: '',
        maxScore: 100,
        deadline: DateTime.now().add(const Duration(days: 1)),
        classId: 'cls_a',
      );

      final taskNotInClass = TaskModel(
        id: 't2',
        title: 'Task B',
        description: '',
        maxScore: 100,
        deadline: DateTime.now().add(const Duration(days: 1)),
        classId: 'cls_z', // student not enrolled here
      );

      expect(enrolledClassIds.contains(taskInClass.classId), isTrue);
      expect(enrolledClassIds.contains(taskNotInClass.classId), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. REPOSITORY TESTS (using fake_cloud_firestore)
  // ─────────────────────────────────────────────────────────────────────────

  group('TaskRepository', () {
    late FakeFirebaseFirestore db;
    late TaskRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = TaskRepository(db);
    });

    test('createTask writes to Firestore and returns document ID', () async {
      final task = TaskModel(
        id: '',
        title: 'New Task',
        description: 'Instructions here',
        maxScore: 80,
        deadline: DateTime(2025, 12, 1),
        instructorId: 'inst_1',
        classId: 'cls_1',
      );

      final id = await repo.createTask(task);

      expect(id, isNotEmpty);

      final doc = await db.collection('tasks').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc['title'], 'New Task');
      expect(doc['classId'], 'cls_1');
      expect(doc['instructorId'], 'inst_1');
    });

    test('getTasksByInstructor returns only that instructor\'s tasks', () async {
      await db.collection('tasks').add({
        'title': 'Task by inst_A',
        'instructorId': 'inst_A',
        'classId': 'cls_1',
        'deadline': Timestamp.fromDate(DateTime.now()),
        'maxScore': 100,
        'description': '',
      });
      await db.collection('tasks').add({
        'title': 'Task by inst_B',
        'instructorId': 'inst_B',
        'classId': 'cls_2',
        'deadline': Timestamp.fromDate(DateTime.now()),
        'maxScore': 100,
        'description': '',
      });

      final tasks =
          await repo.getTasksByInstructor('inst_A').first;

      expect(tasks, hasLength(1));
      expect(tasks.first.title, 'Task by inst_A');
    });

    test('getTasksByClassIds returns tasks for enrolled classes only',
        () async {
      await db.collection('tasks').add({
        'title': 'Class A Task',
        'classId': 'cls_a',
        'instructorId': 'inst_1',
        'deadline': Timestamp.fromDate(DateTime.now()),
        'maxScore': 100,
        'description': '',
      });
      await db.collection('tasks').add({
        'title': 'Class B Task',
        'classId': 'cls_b',
        'instructorId': 'inst_1',
        'deadline': Timestamp.fromDate(DateTime.now()),
        'maxScore': 100,
        'description': '',
      });
      await db.collection('tasks').add({
        'title': 'Class Z Task (not enrolled)',
        'classId': 'cls_z',
        'instructorId': 'inst_1',
        'deadline': Timestamp.fromDate(DateTime.now()),
        'maxScore': 100,
        'description': '',
      });

      final tasks =
          await repo.getTasksByClassIds(['cls_a', 'cls_b']).first;

      expect(tasks, hasLength(2));
      final titles = tasks.map((t) => t.title).toList();
      expect(titles, containsAll(['Class A Task', 'Class B Task']));
      expect(titles, isNot(contains('Class Z Task (not enrolled)')));
    });

    test('getTasksByClassIds returns empty list when classIds is empty',
        () async {
      await db.collection('tasks').add({
        'title': 'Some Task',
        'classId': 'cls_x',
        'instructorId': 'inst_1',
        'deadline': Timestamp.fromDate(DateTime.now()),
        'maxScore': 100,
        'description': '',
      });

      final tasks = await repo.getTasksByClassIds([]).first;
      expect(tasks, isEmpty);
    });

    test('addQuestion writes question to questions collection', () async {
      final question = QuestionModel(
        id: '',
        taskId: 'task_abc',
        questionText: 'What is PE?',
        choices: ['Physical Education', 'Programming', 'Physics'],
        correctAnswerIndex: 0,
      );

      await repo.addQuestion(question);

      final snap = await db
          .collection('questions')
          .where('taskId', isEqualTo: 'task_abc')
          .get();

      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['questionText'], 'What is PE?');
    });

    test('getQuestionsByTask returns correct questions', () async {
      await db.collection('questions').add({
        'taskId': 'task_1',
        'questionText': 'Q for task 1',
        'choices': ['A', 'B'],
        'correctAnswerIndex': 0,
      });
      await db.collection('questions').add({
        'taskId': 'task_2',
        'questionText': 'Q for task 2',
        'choices': ['A', 'B'],
        'correctAnswerIndex': 1,
      });

      final qs = await repo.getQuestionsByTask('task_1').first;
      expect(qs, hasLength(1));
      expect(qs.first.questionText, 'Q for task 1');
    });
  });

  // ── 3b. SubmissionRepository ───────────────────────────────────────────────
  group('SubmissionRepository', () {
    late FakeFirebaseFirestore db;
    late SubmissionRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = SubmissionRepository(db);
    });

    test('createSubmission writes to Firestore', () async {
      final sub = SubmissionModel(
        id: '',
        taskId: 'task_001',
        studentId: 'stu_001',
        studentEmail: 'stu@gmail.com',
        submittedAt: DateTime.now(),
        instructorId: 'inst_001',
      );

      await repo.createSubmission(sub);

      final snap = await db.collection('submissions').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['taskId'], 'task_001');
      expect(snap.docs.first['studentId'], 'stu_001');
    });

    test('updateGrade updates the grade field', () async {
      final docRef = await db.collection('submissions').add({
        'taskId': 'task_001',
        'studentId': 'stu_001',
        'studentEmail': 'stu@gmail.com',
        'grade': null,
        'submittedAt': Timestamp.fromDate(DateTime.now()),
        'instructorId': 'inst_001',
      });

      await repo.updateGrade(docRef.id, '92');

      final updated = await docRef.get();
      expect(updated['grade'], '92');
    });

    test('getSubmissionsByStudent returns only that student\'s submissions',
        () async {
      await db.collection('submissions').add({
        'taskId': 't1',
        'studentId': 'stu_A',
        'studentEmail': 'a@gmail.com',
        'submittedAt': Timestamp.fromDate(DateTime.now()),
        'instructorId': 'inst_1',
      });
      await db.collection('submissions').add({
        'taskId': 't2',
        'studentId': 'stu_B',
        'studentEmail': 'b@gmail.com',
        'submittedAt': Timestamp.fromDate(DateTime.now()),
        'instructorId': 'inst_1',
      });

      final subs =
          await repo.getSubmissionsByStudent('stu_A').first;
      expect(subs, hasLength(1));
      expect(subs.first.studentId, 'stu_A');
    });

    test('getSubmissionsByTask returns submissions for specific task', () async {
      await db.collection('submissions').add({
        'taskId': 'task_target',
        'studentId': 'stu_1',
        'studentEmail': 's1@gmail.com',
        'submittedAt': Timestamp.fromDate(DateTime.now()),
        'instructorId': 'inst_1',
      });
      await db.collection('submissions').add({
        'taskId': 'task_other',
        'studentId': 'stu_2',
        'studentEmail': 's2@gmail.com',
        'submittedAt': Timestamp.fromDate(DateTime.now()),
        'instructorId': 'inst_1',
      });

      final subs =
          await repo.getSubmissionsByTask('task_target').first;
      expect(subs, hasLength(1));
      expect(subs.first.taskId, 'task_target');
    });
  });

  // ── 3c. CourseRepository ───────────────────────────────────────────────────
  group('CourseRepository', () {
    late FakeFirebaseFirestore db;
    late CourseRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = CourseRepository(db);
    });

    test('createCourse writes to Firestore', () async {
      final course = CourseModel(
        id: '',
        name: 'Individual Sports',
        description: 'Focus on individual athletes',
        enrolledStudents: const [],
      );

      await repo.createCourse(course);

      final snap = await db.collection('courses').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['name'], 'Individual Sports');
    });

    test('enrollStudent adds studentId to course and courseId to user',
        () async {
      await db.collection('courses').doc('crs_1').set({
        'name': 'Test Course',
        'description': '',
        'enrolledStudents': [],
      });
      await db.collection('users').doc('stu_1').set({
        'email': 'stu@gmail.com',
        'role': 'student',
        'enrolledCourses': [],
      });

      await repo.enrollStudent(courseId: 'crs_1', studentId: 'stu_1');

      final crsDoc = await db.collection('courses').doc('crs_1').get();
      final stuDoc = await db.collection('users').doc('stu_1').get();

      expect(List<String>.from(crsDoc['enrolledStudents']),
          contains('stu_1'));
      expect(List<String>.from(stuDoc['enrolledCourses']),
          contains('crs_1'));
    });

    test('unenrollStudent removes studentId from both documents', () async {
      await db.collection('courses').doc('crs_1').set({
        'name': 'Test Course',
        'description': '',
        'enrolledStudents': ['stu_1'],
      });
      await db.collection('users').doc('stu_1').set({
        'email': 'stu@gmail.com',
        'role': 'student',
        'enrolledCourses': ['crs_1'],
      });

      await repo.unenrollStudent(courseId: 'crs_1', studentId: 'stu_1');

      final crsDoc = await db.collection('courses').doc('crs_1').get();
      final stuDoc = await db.collection('users').doc('stu_1').get();

      expect(List<String>.from(crsDoc['enrolledStudents']),
          isNot(contains('stu_1')));
      expect(List<String>.from(stuDoc['enrolledCourses']),
          isNot(contains('crs_1')));
    });

    test('getEnrolledCourses returns only courses where student is enrolled',
        () async {
      await db.collection('courses').add({
        'name': 'Enrolled Course',
        'description': '',
        'enrolledStudents': ['stu_1'],
      });
      await db.collection('courses').add({
        'name': 'Not Enrolled Course',
        'description': '',
        'enrolledStudents': ['stu_2'],
      });

      final enrolled = await repo.getEnrolledCourses('stu_1').first;
      expect(enrolled, hasLength(1));
      expect(enrolled.first.name, 'Enrolled Course');
    });

    test('updateCourse updates specific fields', () async {
      await db.collection('courses').doc('crs_1').set({
        'name': 'Old Name',
        'description': 'Old Desc',
        'enrolledStudents': [],
      });

      await repo.updateCourse('crs_1', {
        'name': 'New Name',
        'description': 'New Desc',
      });

      final doc = await db.collection('courses').doc('crs_1').get();
      expect(doc['name'], 'New Name');
      expect(doc['description'], 'New Desc');
    });

    test('deleteCourse removes the document', () async {
      await db.collection('courses').doc('crs_del').set({
        'name': 'To Delete',
        'description': '',
        'enrolledStudents': [],
      });

      await repo.deleteCourse('crs_del');

      final doc = await db.collection('courses').doc('crs_del').get();
      expect(doc.exists, isFalse);
    });
  });

  // ── 3d. ClassRepository ────────────────────────────────────────────────────
  group('ClassRepository', () {
    late FakeFirebaseFirestore db;
    late ClassRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = ClassRepository(db);
    });

    test('createClass adds document to classes collection', () async {
      final cls = ClassModel(
        id: '',
        className: 'BPED 1-A',
        subject: 'Rhythmic Activities',
        schedule: 'MWF 7:00AM',
      );

      await repo.createClass(cls);

      final snap = await db.collection('classes').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['className'], 'BPED 1-A');
    });

    test('enrollStudent adds ids to both documents', () async {
      await db.collection('classes').doc('cls_1').set({
        'className': 'BPED 2-B',
        'subject': 'Team Sports',
        'schedule': 'TTh 1PM',
        'enrolledStudentIds': [],
      });
      await db.collection('users').doc('stu_x').set({
        'email': 'x@gmail.com',
        'enrolledClassIds': [],
      });

      await repo.enrollStudent(classId: 'cls_1', studentId: 'stu_x');

      final clsDoc = await db.collection('classes').doc('cls_1').get();
      final stuDoc = await db.collection('users').doc('stu_x').get();

      expect(List<String>.from(clsDoc['enrolledStudentIds']),
          contains('stu_x'));
      expect(List<String>.from(stuDoc['enrolledClassIds']),
          contains('cls_1'));
    });

    test('unenrollStudent removes from both documents', () async {
      await db.collection('classes').doc('cls_1').set({
        'className': 'BPED 2-B',
        'subject': 'Team Sports',
        'schedule': 'TTh 1PM',
        'enrolledStudentIds': ['stu_x'],
      });
      await db.collection('users').doc('stu_x').set({
        'email': 'x@gmail.com',
        'enrolledClassIds': ['cls_1'],
      });

      await repo.unenrollStudent(classId: 'cls_1', studentId: 'stu_x');

      final clsDoc = await db.collection('classes').doc('cls_1').get();
      final stuDoc = await db.collection('users').doc('stu_x').get();

      expect(List<String>.from(clsDoc['enrolledStudentIds']),
          isNot(contains('stu_x')));
      expect(List<String>.from(stuDoc['enrolledClassIds']),
          isNot(contains('cls_1')));
    });

    test('getClassesForStudent returns only classes the student is in',
        () async {
      await db.collection('classes').doc('cls_a').set({
        'className': 'Class A',
        'subject': 'S1',
        'schedule': 'MWF',
        'enrolledStudentIds': ['stu_1'],
      });
      await db.collection('classes').doc('cls_b').set({
        'className': 'Class B',
        'subject': 'S2',
        'schedule': 'TTh',
        'enrolledStudentIds': ['stu_2'],
      });

      final classes = await repo.getClassesForStudent('stu_1').first;
      expect(classes, hasLength(1));
      expect(classes.first.className, 'Class A');
    });
  });

  // ── 3e. ReviewerRepository ─────────────────────────────────────────────────
  group('ReviewerRepository', () {
    late FakeFirebaseFirestore db;
    late ReviewerRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = ReviewerRepository(db);
    });

    test('uploadReviewer writes to Firestore', () async {
      final reviewer = ReviewerModel(
        id: '',
        title: 'Anatomy Notes',
        fileUrl: 'https://cloudinary.com/file.pdf',
        category: 'Anatomy',
        uploadedAt: DateTime.now(),
        instructorId: 'inst_001',
      );

      await repo.uploadReviewer(reviewer);

      final snap = await db.collection('reviewers').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['title'], 'Anatomy Notes');
    });

    test('getReviewersByInstructor returns only that instructor\'s reviewers',
        () async {
      await db.collection('reviewers').add({
        'title': 'Rev by inst_A',
        'fileUrl': 'url1',
        'category': 'General',
        'instructorId': 'inst_A',
        'uploadedAt': Timestamp.fromDate(DateTime.now()),
      });
      await db.collection('reviewers').add({
        'title': 'Rev by inst_B',
        'fileUrl': 'url2',
        'category': 'General',
        'instructorId': 'inst_B',
        'uploadedAt': Timestamp.fromDate(DateTime.now()),
      });

      final revs =
          await repo.getReviewersByInstructor('inst_A').first;
      expect(revs, hasLength(1));
      expect(revs.first.title, 'Rev by inst_A');
    });
  });

  // ── 3f. LessonRepository ───────────────────────────────────────────────────
  group('LessonRepository', () {
    late FakeFirebaseFirestore db;
    late LessonRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = LessonRepository(db);
    });

    test('addLesson writes to Firestore', () async {
      final lesson = LessonModel(
        id: '',
        courseId: 'crs_1',
        title: 'Warm Up Techniques',
        description: 'Basic warm-up routines',
        category: 'General',
        instructorId: 'inst_001',
      );

      await repo.addLesson(lesson);

      final snap = await db.collection('lessons').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first['title'], 'Warm Up Techniques');
    });

    test('getLessonsByCourse returns lessons for that course only', () async {
      await db.collection('lessons').add({
        'courseId': 'crs_1',
        'title': 'Lesson for Course 1',
        'description': '',
        'instructorId': 'inst_1',
      });
      await db.collection('lessons').add({
        'courseId': 'crs_2',
        'title': 'Lesson for Course 2',
        'description': '',
        'instructorId': 'inst_1',
      });

      final lessons =
          await repo.getLessonsByCourse('crs_1').first;
      expect(lessons, hasLength(1));
      expect(lessons.first.title, 'Lesson for Course 1');
    });

    test('getLessonsByInstructor returns that instructor\'s lessons only',
        () async {
      await db.collection('lessons').add({
        'courseId': 'crs_1',
        'title': 'My Lesson',
        'description': '',
        'instructorId': 'inst_target',
      });
      await db.collection('lessons').add({
        'courseId': 'crs_2',
        'title': 'Other Lesson',
        'description': '',
        'instructorId': 'inst_other',
      });

      final lessons =
          await repo.getLessonsByInstructor('inst_target').first;
      expect(lessons, hasLength(1));
      expect(lessons.first.instructorId, 'inst_target');
    });
  });
}
