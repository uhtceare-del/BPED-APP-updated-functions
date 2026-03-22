import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _db = FirebaseFirestore.instance;

// ── Users ─────────────────────────────────────────────────────────────────────

final adminUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return _db
      .collection('users')
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

// ── Summary counts (reports) ──────────────────────────────────────────────────

final adminSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final results = await Future.wait([
    _db.collection('users').where('role', isEqualTo: 'student').count().get(),
    _db.collection('courses').count().get(),
    _db.collection('tasks').count().get(),
    _db.collection('submissions').count().get(),
  ]);
  return {
    'students': results[0].count ?? 0,
    'courses': results[1].count ?? 0,
    'tasks': results[2].count ?? 0,
    'submissions': results[3].count ?? 0,
  };
});

// ── Grade distribution ────────────────────────────────────────────────────────

final adminGradesProvider = FutureProvider<Map<String, int>>((ref) async {
  final snap = await _db
      .collection('submissions')
      .where('grade', isNotEqualTo: null)
      .get();

  final buckets = {
    '90-100': 0,
    '75-89': 0,
    '60-74': 0,
    '50-59': 0,
    'Below 50': 0,
  };

  for (final doc in snap.docs) {
    final grade = int.tryParse(doc.data()['grade']?.toString() ?? '');
    if (grade == null) continue;
    if (grade >= 90)
      buckets['90-100'] = buckets['90-100']! + 1;
    else if (grade >= 75)
      buckets['75-89'] = buckets['75-89']! + 1;
    else if (grade >= 60)
      buckets['60-74'] = buckets['60-74']! + 1;
    else if (grade >= 50)
      buckets['50-59'] = buckets['50-59']! + 1;
    else
      buckets['Below 50'] = buckets['Below 50']! + 1;
  }
  return buckets;
});

// ── Lessons (all, for admin uploads tab) ─────────────────────────────────────

final adminLessonsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return _db
      .collection('lessons')
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

// ── Reviewers (all, for admin uploads tab) ────────────────────────────────────

final adminReviewersProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return _db
      .collection('reviewers')
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

// ── Firestore helpers (called from UI actions) ────────────────────────────────

Future<void> adminCreateUser(Map<String, dynamic> data) async {
  final ref = await _db.collection('users').add(data);
  await ref.update({'uid': ref.id});
}

Future<void> adminUpdateUser(String uid, Map<String, dynamic> data) =>
    _db.collection('users').doc(uid).update(data);

Future<void> adminDeleteUser(String uid) =>
    _db.collection('users').doc(uid).delete();

Future<void> adminUpdateLesson(String id, Map<String, dynamic> data) =>
    _db.collection('lessons').doc(id).update(data);

Future<void> adminDeleteLesson(String id) =>
    _db.collection('lessons').doc(id).delete();

Future<void> adminUpdateReviewer(String id, Map<String, dynamic> data) =>
    _db.collection('reviewers').doc(id).update(data);

Future<void> adminDeleteReviewer(String id) =>
    _db.collection('reviewers').doc(id).delete();
