import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/reviewer_provider.dart';
import '../providers/class_provider.dart';
import '../providers/cloudinary_provider.dart';
import '../providers/auth_provider.dart';
import '../models/reviewer_model.dart';
import '../widgets/pdf_viewer_widget.dart';

class ReviewerScreen extends ConsumerStatefulWidget {
  const ReviewerScreen({super.key});

  @override
  ConsumerState<ReviewerScreen> createState() => _ReviewerScreenState();
}

class _ReviewerScreenState extends ConsumerState<ReviewerScreen> {
  static const Color lnuNavy = Color(0xFF002147);

  final Map<String, bool> _downloadingMap = {};
  final Map<String, double> _progressMap = {};

  // ── View (web: in-app PDF viewer) ───────────────────────────────────────────

  void _viewReviewer(ReviewerModel reviewer) {
    if (reviewer.fileUrl.isEmpty) {
      _snack('No file URL found for this reviewer.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerWidget(
          title: reviewer.title,
          urlOrPath: reviewer.fileUrl,
          isOffline: false,
        ),
      ),
    );
  }

  // ── Download + open (mobile only) ───────────────────────────────────────────
  // Fix: always save with .pdf extension so OpenFile can detect the type.

  Future<void> _downloadAndOpen(ReviewerModel reviewer) async {
    if (reviewer.fileUrl.isEmpty) {
      _snack('No file URL found.');
      return;
    }
    if (_downloadingMap[reviewer.id] == true) return;

    setState(() {
      _downloadingMap[reviewer.id] = true;
      _progressMap[reviewer.id] = 0.0;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      // Always end in .pdf so OpenFile recognises the MIME type
      final safeFileName =
          reviewer.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final savePath = '${directory.path}/${safeFileName}_${reviewer.id}.pdf';
      final file = File(savePath);

      if (!await file.exists()) {
        final dio = Dio();
        await dio.download(
          reviewer.fileUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1 && mounted) {
              setState(
                  () => _progressMap[reviewer.id] = received / total);
            }
          },
        );
      }

      if (mounted) _snack('Download complete. Opening…');
      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done && mounted) {
        _snack('Could not open file: ${result.message}');
      }
    } catch (e) {
      if (mounted) _snack('Download failed: $e');
    } finally {
      if (mounted) setState(() => _downloadingMap[reviewer.id] = false);
    }
  }

  Future<void> _deleteReviewer(
      BuildContext context, ReviewerModel reviewer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Reviewer',
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text("Delete '${reviewer.title}'? This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('reviewers')
          .doc(reviewer.id)
          .delete();
      if (mounted) _snack('Reviewer deleted.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reviewersAsync = ref.watch(allReviewersProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isInstructor = currentUser?.role.toLowerCase() == 'instructor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: reviewersAsync.when(
        data: (reviewers) {
          if (reviewers.isEmpty) return _buildEmptyState(isInstructor);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviewers.length,
            itemBuilder: (_, index) {
              final reviewer = reviewers[index];
              final isDownloading = _downloadingMap[reviewer.id] ?? false;
              final progress = _progressMap[reviewer.id] ?? 0.0;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // PDF icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf,
                            color: Colors.red, size: 22),
                      ),
                      const SizedBox(width: 12),

                      // Title + subject chip
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reviewer.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: lnuNavy.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              // Show subject if available, fall back to category
                              child: Text(
                                reviewer.subject.isNotEmpty
                                    ? reviewer.subject
                                    : reviewer.category,
                                style: const TextStyle(
                                    fontSize: 11, color: lnuNavy),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ── Instructor actions ─────────────────────────────
                      if (isInstructor)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined,
                                  color: Colors.blueAccent),
                              tooltip: 'Preview',
                              onPressed: () => _viewReviewer(reviewer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              tooltip: 'Delete',
                              onPressed: () =>
                                  _deleteReviewer(context, reviewer),
                            ),
                          ],
                        )

                      // ── Student actions ────────────────────────────────
                      else if (isDownloading)
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            strokeWidth: 3,
                            color: lnuNavy,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // View button (web: in-app PDF; mobile: also in-app)
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined,
                                  color: Colors.blueAccent),
                              tooltip: 'View PDF',
                              onPressed: () => _viewReviewer(reviewer),
                            ),
                            // Download button (mobile only)
                            if (!kIsWeb)
                              IconButton(
                                icon: const Icon(
                                    Icons.download_outlined,
                                    color: Colors.blueGrey),
                                tooltip: 'Download & Open',
                                onPressed: () =>
                                    _downloadAndOpen(reviewer),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: isInstructor
          ? FloatingActionButton.extended(
              backgroundColor: lnuNavy,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => const _UploadReviewerSheet(),
              ),
              label: const Text('Upload Reviewer',
                  style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.upload_file, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isInstructor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.picture_as_pdf_rounded,
                size: 80, color: Colors.red.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          const Text('No Reviewers Available',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002147))),
          const SizedBox(height: 8),
          Text(
            isInstructor
                ? 'Tap the button below to upload a PDF reviewer.'
                : 'Your instructors have not uploaded any reviewers yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Upload sheet ──────────────────────────────────────────────────────────────
// Now includes a class picker — classId is stored on each reviewer document.

class _UploadReviewerSheet extends ConsumerStatefulWidget {
  const _UploadReviewerSheet();

  @override
  ConsumerState<_UploadReviewerSheet> createState() =>
      _UploadReviewerSheetState();
}

class _UploadReviewerSheetState
    extends ConsumerState<_UploadReviewerSheet> {
  static const Color lnuNavy = Color(0xFF002147);

  final _titleController = TextEditingController();
  String? _selectedSubject;   // renamed from _selectedCategory
  String? _selectedClassId;   // NEW — class picker

  String? _filePath;
  Uint8List? _fileBytes;
  String? _fileName;

  bool _isUploading = false;

  bool get _hasFile => kIsWeb ? _fileBytes != null : _filePath != null;

  // Subjects list mirrors create_lesson_screen.dart
  final List<String> _subjects = [
    'Anatomy & Physiology',
    'Kinesiology',
    'Sports Psychology',
    'Pedagogy in PE',
    'Sports Technique',
    'Sports Management',
    'Team Sports',
    'Individual Sports',
    'Aquatics',
    'Dance & Rhythmic Activities',
    'Physical Fitness',
    'General',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FocusScope.of(context).unfocus();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() {
      _fileName = file.name;
      if (kIsWeb) {
        _fileBytes = file.bytes;
        _filePath = null;
      } else {
        _filePath = file.path;
        _fileBytes = null;
      }
    });
  }

  Future<void> _upload() async {
    if (_titleController.text.trim().isEmpty) {
      _snack('Please enter a title.');
      return;
    }
    if (_selectedSubject == null) {
      _snack('Please select a subject.');
      return;
    }
    if (_selectedClassId == null) {
      _snack('Please select a class section.');
      return;
    }
    if (!_hasFile) {
      _snack('Please pick a PDF file first.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final cloudinary = ref.read(cloudinaryProvider);
      final instructorId =
          ref.read(authControllerProvider).currentUser?.uid ?? '';

      String? url;
      if (kIsWeb) {
        url = await cloudinary.uploadBytes(_fileBytes!,
            filename: _fileName ?? 'reviewer.pdf');
      } else {
        url = await cloudinary.uploadPdf(_filePath!);
      }

      if (url == null || url.isEmpty) {
        throw Exception(
            'Cloudinary returned no URL. Check that your upload preset allows raw files.');
      }

      final reviewer = ReviewerModel(
        id: '',
        title: _titleController.text.trim(),
        fileUrl: url,
        subject: _selectedSubject!,     // stored as 'subject'
        classId: _selectedClassId!,     // NEW — scopes reviewer to class
        uploadedAt: DateTime.now(),
        instructorId: instructorId,
      );

      await ref.read(reviewerRepositoryProvider).uploadReviewer(reviewer);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reviewer uploaded successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _snack('Upload failed: $e');
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(allClassesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 28,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Upload Reviewer PDF',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: lnuNavy)),
          const SizedBox(height: 20),

          // Title
          TextField(
            controller: _titleController,
            enabled: !_isUploading,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),

          // Subject dropdown (renamed from Category)
          DropdownButtonFormField<String>(
            initialValue: _selectedSubject,
            decoration: const InputDecoration(
                labelText: 'Subject', border: OutlineInputBorder()),
            items: _subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: _isUploading
                ? null
                : (v) => setState(() => _selectedSubject = v),
          ),
          const SizedBox(height: 14),

          // Class picker — NEW
          classesAsync.when(
            data: (classes) => DropdownButtonFormField<String>(
              initialValue: _selectedClassId,
              decoration: const InputDecoration(
                  labelText: 'Class Section',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups_outlined)),
              hint: const Text('Select Class Section'),
              items: classes
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.className} — ${c.subject}'),
                      ))
                  .toList(),
              onChanged: _isUploading
                  ? null
                  : (v) => setState(() => _selectedClassId = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Could not load classes'),
          ),
          const SizedBox(height: 14),

          // File picker
          InkWell(
            onTap: _isUploading ? null : _pickFile,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _hasFile ? Colors.red.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _hasFile
                        ? Colors.red.shade300
                        : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasFile ? Icons.picture_as_pdf : Icons.attach_file,
                    color: _hasFile ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fileName ?? 'Tap to pick a PDF file',
                      style: TextStyle(
                          color: _hasFile ? Colors.black87 : Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_hasFile)
                    const Icon(Icons.check_circle,
                        color: Colors.red, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Upload button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lnuNavy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isUploading ? null : _upload,
              child: _isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Uploading…',
                            style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text('UPLOAD',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
