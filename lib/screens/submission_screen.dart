import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/submission_model.dart';
import '../providers/submission_provider.dart';
import '../providers/auth_provider.dart';

// ── Role-scoped submissions provider ────────────────────────────────────────
// Instructors see all submissions for tasks they assigned (filtered by
// instructorId). Students see only their own submissions.
// This replaces the old submissionProvider which returned everything.
final securedSubmissionsProvider =
    StreamProvider.autoDispose<List<SubmissionModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);

  final isInstructor = user.role.toLowerCase() == 'instructor';
  final db = FirebaseFirestore.instance;

  if (isInstructor) {
    return db
        .collection('submissions')
        .where('instructorId', isEqualTo: user.uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubmissionModel.fromFirestore(doc))
            .toList());
  } else {
    return db
        .collection('submissions')
        .where('studentId', isEqualTo: user.uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubmissionModel.fromFirestore(doc))
            .toList());
  }
});

// ── Screen ───────────────────────────────────────────────────────────────────

class SubmissionScreen extends ConsumerWidget {
  const SubmissionScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(securedSubmissionsProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isInstructor = currentUser?.role.toLowerCase() == 'instructor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: submissionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (submissions) {
          if (submissions.isEmpty) {
            return _buildEmptyState(isInstructor);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final sub = submissions[index];
              final isGraded =
                  sub.grade != null && sub.grade!.isNotEmpty;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isGraded
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    child: Icon(
                      isGraded ? Icons.check_circle : Icons.hourglass_top,
                      color: isGraded ? Colors.green : Colors.orange,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    sub.studentEmail,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Submitted: ${sub.submittedAt.month}/${sub.submittedAt.day}/${sub.submittedAt.year}',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isGraded
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isGraded ? 'Grade: ${sub.grade}' : 'Pending',
                      style: TextStyle(
                          color: isGraded
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  // Only instructors can tap to open the grading dialog
                  onTap: isInstructor
                      ? () => _showGradingDialog(context, ref, sub)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isInstructor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isInstructor
                ? 'No submissions yet.'
                : 'You have not submitted any tasks yet.',
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Grading dialog ──────────────────────────────────────────────────────────

  void _showGradingDialog(
      BuildContext context, WidgetRef ref, SubmissionModel submission) {
    final gradeController =
        TextEditingController(text: submission.grade);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Review Submission',
            style: TextStyle(
                color: lnuNavy, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── View student file button ─────────────────────────────────
            if (submission.fileUrl != null &&
                submission.fileUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(submission.fileUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('VIEW STUDENT FILE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            if (submission.fileUrl == null ||
                submission.fileUrl!.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'No file attached to this submission.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            // ── Grade input ──────────────────────────────────────────────
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Grade',
                hintText: 'e.g. 95',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grade_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: lnuNavy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await ref
                  .read(submissionRepositoryProvider)
                  .updateGrade(
                      submission.id, gradeController.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('SAVE GRADE',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
