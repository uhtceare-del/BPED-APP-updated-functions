import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/question_model.dart';
import '../models/submission_model.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/submission_provider.dart';

class TakeQuizScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TakeQuizScreen({super.key, required this.task});

  @override
  ConsumerState<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends ConsumerState<TakeQuizScreen> {
  static const Color lnuNavy = Color(0xFF002147);

  /// Maps question ID → selected choice index
  final Map<String, int> _selectedAnswers = {};
  bool _isSubmitting = false;

  // ── Grading ───────────────────────────────────────────────────────────────

  Future<void> _submitQuiz(List<QuestionModel> questions) async {
    // Guard: all questions must be answered
    if (_selectedAnswers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Count correct answers
      int correct = 0;
      for (final q in questions) {
        if (_selectedAnswers[q.id] == q.correctAnswerIndex) correct++;
      }

      // Calculate proportional score rounded to nearest integer
      final rawScore = (correct / questions.length) * widget.task.maxScore;
      final finalGrade = rawScore.round().toString();

      final user = ref.read(authControllerProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      // Build submission — instructorId is required so the instructor's
      // securedSubmissionsProvider can find this submission
      final submission = SubmissionModel(
        id: '',
        taskId: widget.task.id,
        studentId: user.uid,
        studentEmail: user.email ?? 'Unknown',
        submittedAt: DateTime.now(),
        grade: finalGrade,
        instructorId: widget.task.instructorId, // ← critical for scoping
      );

      await ref.read(submissionRepositoryProvider).createSubmission(submission);

      if (mounted) {
        _showResultsDialog(correct, questions.length, finalGrade);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Submission failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showResultsDialog(int correct, int total, String finalGrade) {
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final passed = int.tryParse(finalGrade) != null &&
        int.parse(finalGrade) >= (widget.task.maxScore * 0.5).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.sentiment_neutral,
              color: passed ? Colors.amber : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text('Quiz Complete!',
                style: TextStyle(
                    color: lnuNavy, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 12),
            // Score circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: passed
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                border: Border.all(
                  color: passed
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                  width: 3,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      finalGrade,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: passed
                              ? Colors.green.shade700
                              : Colors.orange.shade700),
                    ),
                    Text(
                      '/ ${widget.task.maxScore}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$correct out of $total correct ($pct%)',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              passed ? 'Great job! Keep it up.' : 'Keep studying — you can do better!',
              style: TextStyle(
                  color: passed ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lnuNavy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);   // close dialog
                Navigator.pop(context); // return to task detail / dashboard
              },
              child: const Text('BACK TO DASHBOARD',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final questionsAsync =
        ref.watch(questionsByTaskProvider(widget.task.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.task.title,
            style: const TextStyle(
                color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: lnuNavy),
        elevation: 0.5,
      ),
      body: questionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.black12),
                  SizedBox(height: 16),
                  Text('No questions for this quiz.',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ── Progress bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedAnswers.length} / ${questions.length} answered',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: lnuNavy.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${widget.task.maxScore} pts',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: lnuNavy,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: questions.isEmpty
                            ? 0
                            : _selectedAnswers.length / questions.length,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(lnuNavy),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Instructions ────────────────────────────────────────────
              if (widget.task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.task.description,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Questions list ──────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final isAnswered =
                        _selectedAnswers.containsKey(question.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isAnswered
                              ? lnuNavy.withOpacity(0.3)
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question number + text
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isAnswered
                                        ? lnuNavy
                                        : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isAnswered
                                              ? Colors.white
                                              : Colors.grey.shade600),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    question.questionText,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            // Choices
                            ...List.generate(
                              question.choices.length,
                              (choiceIndex) {
                                final isSelected = _selectedAnswers[
                                        question.id] ==
                                    choiceIndex;
                                return InkWell(
                                  onTap: () => setState(() {
                                    _selectedAnswers[question.id] =
                                        choiceIndex;
                                  }),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? lnuNavy.withOpacity(0.08)
                                          : Colors.grey.shade50,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? lnuNavy
                                            : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? lnuNavy
                                                  : Colors.grey.shade400,
                                              width: 2,
                                            ),
                                            color: isSelected
                                                ? lnuNavy
                                                : Colors.transparent,
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check,
                                                  size: 12,
                                                  color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            question.choices[choiceIndex],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isSelected
                                                  ? lnuNavy
                                                  : Colors.black87,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Submit button ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAnswers.length ==
                              questions.length
                          ? lnuNavy
                          : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitQuiz(questions),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _selectedAnswers.length == questions.length
                                ? 'SUBMIT ANSWERS'
                                : 'Answer all questions to submit',
                            style: TextStyle(
                              color: _selectedAnswers.length ==
                                      questions.length
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
