import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lesson_provider.dart';
import '../models/lesson_model.dart';
import 'create_lesson_screen.dart';
import 'lesson_detail_screen.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(allLessonsProvider);

    return Scaffold(
      body: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No lessons created yet.',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Text('Tap the button below to add one.',
                      style: TextStyle(color: Colors.black38, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return _LessonTile(lesson: lesson);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: lnuNavy,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateLessonScreen()),
        ),
        label: const Text('Add Lesson', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final LessonModel lesson;

  const _LessonTile({required this.lesson});

  static const Color lnuNavy = Color(0xFF002147);

  // Show category or subject, whichever is present
  String? get _displaySubject {
    if (lesson.subject?.isNotEmpty ?? false) return lesson.subject;
    if (lesson.category?.isNotEmpty ?? false) return lesson.category;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasPdf = lesson.pdfUrl != null && lesson.pdfUrl!.isNotEmpty;
    final hasAudio = lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(lesson: lesson),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lnuNavy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book, color: lnuNavy, size: 22),
              ),
              const SizedBox(width: 14),

              // Title + subject + media badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (_displaySubject != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(_displaySubject!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (hasVideo)
                          _MediaBadge(
                              icon: Icons.videocam,
                              label: 'Video',
                              color: Colors.blue),
                        if (hasPdf)
                          _MediaBadge(
                              icon: Icons.picture_as_pdf,
                              label: 'PDF',
                              color: Colors.red),
                        if (hasAudio)
                          _MediaBadge(
                              icon: Icons.headphones,
                              label: 'Audio',
                              color: Colors.purple),
                        if (!hasVideo && !hasPdf && !hasAudio)
                          _MediaBadge(
                              icon: Icons.text_snippet_outlined,
                              label: 'Text only',
                              color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.chevron_right,
                    color: Colors.grey.shade400, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MediaBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
