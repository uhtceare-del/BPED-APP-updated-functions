import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task_model.dart';
import '../models/submission_model.dart';
import '../providers/task_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cloudinary_provider.dart';
import 'take_quiz_screen.dart';

class StudentTaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const StudentTaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<StudentTaskDetailScreen> createState() =>
      _StudentTaskDetailScreenState();
}

class _StudentTaskDetailScreenState
    extends ConsumerState<StudentTaskDetailScreen> {
  static const Color lnuNavy = Color(0xFF002147);

  String? _filePath;
  bool _isSubmitting = false;

  bool get _isPastDeadline => DateTime.now().isAfter(widget.task.deadline);

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _filePath = result.files.single.path);
    }
  }

  Future<void> _submitTask() async {
    final user = ref.read(authControllerProvider).currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload the file if one was attached
      String? fileUrl;
      if (_filePath != null) {
        fileUrl = await ref.read(cloudinaryProvider).uploadFile(_filePath!);
      }

      final submission = SubmissionModel(
        id: '',
        taskId: widget.task.id,
        studentId: user.uid,
        studentEmail: user.email ?? '',
        submittedAt: DateTime.now(),
        grade: null,
        fileUrl: fileUrl,                        // ← pass uploaded URL
        instructorId: widget.task.instructorId,  // ← master key for scoping
      );

      await ref
          .read(submissionRepositoryProvider)
          .createSubmission(submission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync =
        ref.watch(questionsByTaskProvider(widget.task.id));
    final mySubsAsync = ref.watch(mySubmissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title,
            style: const TextStyle(
                color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: lnuNavy),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Deadline row ──────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  _isPastDeadline
                      ? Icons.event_busy
                      : Icons.event_available,
                  color: _isPastDeadline ? Colors.red : Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Due: ${widget.task.deadline.month}/${widget.task.deadline.day}/${widget.task.deadline.year}',
                  style: TextStyle(
                    color: _isPastDeadline ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: lnuNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${widget.task.maxScore} pts',
                      style: const TextStyle(
                          color: lnuNavy,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Instructions ──────────────────────────────────────────────
            const Text('Instructions',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(widget.task.description,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
            const SizedBox(height: 24),

            // ── Submission state ──────────────────────────────────────────
            mySubsAsync.when(
              data: (subs) {
                final alreadySubmitted =
                    subs.any((s) => s.taskId == widget.task.id);

                if (alreadySubmitted) {
                  final sub =
                      subs.firstWhere((s) => s.taskId == widget.task.id);
                  return _buildAlreadySubmittedCard(sub);
                }

                if (_isPastDeadline) {
                  return _buildDeadlinePassedCard();
                }

                // Determine quiz vs file submission
                return questionsAsync.when(
                  data: (questions) {
                    if (questions.isNotEmpty) {
                      return _buildQuizCard(questions.length);
                    }
                    return _buildFileSubmissionSection();
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quiz card ─────────────────────────────────────────────────────────────

  Widget _buildQuizCard(int questionCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.quiz_outlined,
                  color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This task is a quiz',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  Text(
                    '$questionCount question${questionCount == 1 ? '' : 's'} • ${widget.task.maxScore} pts',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: lnuNavy,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TakeQuizScreen(task: widget.task)),
          ),
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text('START QUIZ',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ── File submission section ───────────────────────────────────────────────

  Widget _buildFileSubmissionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Submit Your Work',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blueGrey,
                letterSpacing: 0.8)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _filePath != null
                  ? lnuNavy.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _filePath != null
                      ? lnuNavy.withOpacity(0.4)
                      : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  _filePath != null
                      ? Icons.attach_file
                      : Icons.upload_file,
                  color: _filePath != null ? lnuNavy : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _filePath != null
                        ? _filePath!.split('/').last
                        : 'Tap to attach a file (PDF, video, image)',
                    style: TextStyle(
                        color: _filePath != null
                            ? Colors.black87
                            : Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_filePath != null)
                  Icon(Icons.check_circle, color: lnuNavy, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: lnuNavy,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitting ? null : _submitTask,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('SUBMIT TASK',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ── Already submitted card ────────────────────────────────────────────────

  Widget _buildAlreadySubmittedCard(SubmissionModel sub) {
    final isGraded = sub.grade != null && sub.grade!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGraded ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isGraded
                ? Colors.green.shade200
                : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isGraded ? Icons.check_circle : Icons.hourglass_top,
            color: isGraded ? Colors.green : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isGraded ? 'Graded' : 'Submitted — Awaiting Grade',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isGraded ? Colors.green : Colors.orange),
              ),
              if (isGraded)
                Text('Score: ${sub.grade} / ${widget.task.maxScore}',
                    style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Deadline passed card ──────────────────────────────────────────────────

  Widget _buildDeadlinePassedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_busy, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text('Deadline has passed.',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red)),
        ],
      ),
    );
  }
}
