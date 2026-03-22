import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_model.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/download_button.dart';

class LessonDetailScreen extends ConsumerWidget {
  final LessonModel lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasPdf = lesson.pdfUrl != null && lesson.pdfUrl!.isNotEmpty;
    final hasAudio = lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty;

    final subject = (lesson.subject?.isNotEmpty ?? false)
        ? lesson.subject!
        : (lesson.category?.isNotEmpty ?? false)
            ? lesson.category!
            : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Collapsible header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: lnuNavy,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.fromLTRB(56, 0, 16, 16),
              title: Text(
                lesson.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      lnuNavy,
                      lnuNavy.withOpacity(0.75),
                    ],
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 60, 20, 48),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu_book,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      if (subject != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            subject,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description card
                  if (lesson.description.isNotEmpty) ...[
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                              icon: Icons.description_outlined,
                              label: 'Description'),
                          const SizedBox(height: 10),
                          Text(
                            lesson.description,
                            style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Attachments
                  if (hasVideo || hasPdf || hasAudio) ...[
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                              icon: Icons.attach_file_rounded,
                              label: 'Attachments'),
                          const SizedBox(height: 12),

                          // ── Video ─────────────────────────────────────
                          if (hasVideo) ...[
                            _AttachmentTile(
                              icon: Icons.play_circle_fill_rounded,
                              iconColor: Colors.blue,
                              label: 'Video Lecture',
                              subtitle: 'Tap to play video',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoPlayerWidget(
                                    title: lesson.title,
                                    urlOrPath: lesson.videoUrl!,
                                    isOffline: false,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // ── PDF ──────────────────────────────────────
                          if (hasPdf) ...[
                            _AttachmentTileWithDownload(
                              icon: Icons.picture_as_pdf_rounded,
                              iconColor: Colors.red,
                              label: 'PDF Document',
                              subtitle: 'View or download',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewerWidget(
                                    title: lesson.title,
                                    urlOrPath: lesson.pdfUrl!,
                                    isOffline: false,
                                  ),
                                ),
                              ),
                              downloadButton: DownloadButton(
                                materialId: '${lesson.id}_pdf',
                                title: '${lesson.title} (PDF)',
                                url: lesson.pdfUrl!,
                                fileExtension: '.pdf',
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // ── Audio ────────────────────────────────────
                          if (hasAudio) ...[
                            _AttachmentTile(
                              icon: Icons.headphones_rounded,
                              iconColor: Colors.purple,
                              label: 'Audio Lecture',
                              subtitle: 'Tap to listen',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AudioPlayerWidget(
                                    title: lesson.title,
                                    urlOrPath: lesson.audioUrl!,
                                    isOffline: false,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // No attachments
                  if (!hasVideo && !hasPdf && !hasAudio)
                    _SectionCard(
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey.shade400),
                          const SizedBox(width: 12),
                          const Text('No attachments for this lesson.',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: lnuNavy.withOpacity(0.6)),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.blueGrey.shade600,
          ),
        ),
      ],
    );
  }
}

// ── Attachment tile (tap only) ────────────────────────────────────────────────

class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: iconColor.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey.shade800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: iconColor.withOpacity(0.6), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Attachment tile with download button ──────────────────────────────────────

class _AttachmentTileWithDownload extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Widget downloadButton;

  const _AttachmentTileWithDownload({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.downloadButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Main tap area
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey.shade800)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new,
                      color: iconColor.withOpacity(0.6), size: 18),
                ],
              ),
            ),
          ),
          // Divider + download row
          Divider(height: 1, color: iconColor.withOpacity(0.15)),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.download_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text('Save for offline use',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                const Spacer(),
                downloadButton,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
