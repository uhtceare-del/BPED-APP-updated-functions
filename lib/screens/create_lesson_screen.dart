import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/lesson_model.dart';
import '../providers/course_provider.dart';
import '../providers/class_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/cloudinary_provider.dart';
import '../providers/auth_provider.dart';

class CreateLessonScreen extends ConsumerStatefulWidget {
  const CreateLessonScreen({super.key});

  @override
  ConsumerState<CreateLessonScreen> createState() =>
      _CreateLessonScreenState();
}

class _CreateLessonScreenState extends ConsumerState<CreateLessonScreen> {
  static const Color lnuNavy = Color(0xFF002147);

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCourseId;
  String? _selectedClassId;  // NEW — class picker
  String? _selectedSubject;  // renamed from _selectedCategory

  // Mobile: file paths
  String? _videoFilePath;
  String? _pdfFilePath;
  String? _audioFilePath;

  // Web: file bytes + names
  Uint8List? _videoBytes;
  Uint8List? _pdfBytes;
  Uint8List? _audioBytes;
  String? _videoFileName;
  String? _pdfFileName;
  String? _audioFileName;

  bool _isUploading = false;

  // Subjects reflect actual BPED course subjects
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

  String? _getFileName(String type) {
    switch (type) {
      case 'video':
        return kIsWeb ? _videoFileName : _videoFilePath?.split('/').last;
      case 'pdf':
        return kIsWeb ? _pdfFileName : _pdfFilePath?.split('/').last;
      case 'audio':
        return kIsWeb ? _audioFileName : _audioFilePath?.split('/').last;
    }
    return null;
  }

  bool _hasFile(String type) {
    if (kIsWeb) {
      switch (type) {
        case 'video': return _videoBytes != null;
        case 'pdf':   return _pdfBytes != null;
        case 'audio': return _audioBytes != null;
      }
    } else {
      switch (type) {
        case 'video': return _videoFilePath != null;
        case 'pdf':   return _pdfFilePath != null;
        case 'audio': return _audioFilePath != null;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    List<String> extensions;
    switch (type) {
      case 'video': extensions = ['mp4', 'mov', 'avi']; break;
      case 'pdf':   extensions = ['pdf']; break;
      case 'audio': extensions = ['mp3', 'm4a', 'wav', 'aac']; break;
      default: return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;

    setState(() {
      if (kIsWeb) {
        switch (type) {
          case 'video': _videoBytes = file.bytes; _videoFileName = file.name; break;
          case 'pdf':   _pdfBytes   = file.bytes; _pdfFileName   = file.name; break;
          case 'audio': _audioBytes = file.bytes; _audioFileName = file.name; break;
        }
      } else {
        switch (type) {
          case 'video': _videoFilePath = file.path; break;
          case 'pdf':   _pdfFilePath   = file.path; break;
          case 'audio': _audioFilePath = file.path; break;
        }
      }
    });
  }

  Future<void> _saveLesson() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course.')),
      );
      return;
    }
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class section.')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a lesson title.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final cloudinary = ref.read(cloudinaryProvider);
      final instructorId =
          ref.read(authControllerProvider).currentUser?.uid ?? '';

      String? videoUrl;
      String? pdfUrl;
      String? audioUrl;

      if (kIsWeb) {
        if (_videoBytes != null) {
          videoUrl = await cloudinary.uploadBytes(_videoBytes!,
              filename: _videoFileName ?? 'video.mp4');
        }
        if (_pdfBytes != null) {
          pdfUrl = await cloudinary.uploadBytes(_pdfBytes!,
              filename: _pdfFileName ?? 'document.pdf');
        }
        if (_audioBytes != null) {
          audioUrl = await cloudinary.uploadBytes(_audioBytes!,
              filename: _audioFileName ?? 'audio.mp3');
        }
      } else {
        if (_videoFilePath != null) {
          videoUrl = await cloudinary.uploadFile(_videoFilePath!);
        }
        if (_pdfFilePath != null) {
          pdfUrl = await cloudinary.uploadFile(_pdfFilePath!);
        }
        if (_audioFilePath != null) {
          audioUrl = await cloudinary.uploadFile(_audioFilePath!);
        }
      }

      final newLesson = LessonModel(
        id: '',
        courseId: _selectedCourseId!,
        classId: _selectedClassId!,          // NEW — scopes lesson to class
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        subject: _selectedSubject ?? 'General', // renamed from category
        videoUrl: videoUrl,
        pdfUrl: pdfUrl,
        audioUrl: audioUrl,
        instructorId: instructorId,
      );

      await ref.read(lessonRepositoryProvider).addLesson(newLesson);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson published successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final classesAsync = ref.watch(allClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Lesson',
            style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: lnuNavy),
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Course selector ──────────────────────────────────────────────
          const _FieldLabel(text: 'Course'),
          const SizedBox(height: 6),
          coursesAsync.when(
            data: (courses) => DropdownButtonFormField<String>(
              hint: const Text('Select Course'),
              initialValue: _selectedCourseId,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined)),
              items: courses
                  .map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCourseId = val),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Error loading courses'),
          ),
          const SizedBox(height: 16),

          // ── Class section picker ─────────────────────────────────────────
          const _FieldLabel(text: 'Class Section'),
          const SizedBox(height: 6),
          classesAsync.when(
            data: (classes) => DropdownButtonFormField<String>(
              hint: const Text('Select Class Section'),
              initialValue: _selectedClassId,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups_outlined)),
              items: classes
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.className} — ${c.subject}'),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedClassId = val),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Error loading classes'),
          ),
          const SizedBox(height: 16),

          // ── Subject selector (renamed from Category) ─────────────────────
          const _FieldLabel(text: 'Subject'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            hint: const Text('Select Subject'),
            initialValue: _selectedSubject,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject_outlined)),
            items: _subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => setState(() => _selectedSubject = val),
          ),
          const SizedBox(height: 16),

          // ── Title ────────────────────────────────────────────────────────
          const _FieldLabel(text: 'Lesson Title'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'e.g. Introduction to Kinesiology',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          // ── Description ──────────────────────────────────────────────────
          const _FieldLabel(text: 'Description'),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'What will students learn from this lesson?',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),

          // ── Attach media ─────────────────────────────────────────────────
          const Text('ATTACH MEDIA',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: Colors.blueGrey)),
          const SizedBox(height: 12),

          _buildFilePicker(
            icon: Icons.videocam_outlined,
            label: 'Video Lecture',
            type: 'video',
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildFilePicker(
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDF Document',
            type: 'pdf',
            color: Colors.red,
          ),
          const SizedBox(height: 10),
          _buildFilePicker(
            icon: Icons.headphones_outlined,
            label: 'Audio Lecture',
            type: 'audio',
            color: Colors.purple,
          ),
          const SizedBox(height: 32),

          // ── Publish button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lnuNavy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isUploading ? null : _saveLesson,
              child: _isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Uploading…',
                            style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text('PUBLISH LESSON',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFilePicker({
    required IconData icon,
    required String label,
    required String type,
    required Color color,
  }) {
    final hasFile = _hasFile(type);
    final fileName = _getFileName(type);

    return InkWell(
      onTap: _isUploading ? null : () => _pickFile(type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasFile ? color.withOpacity(0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  hasFile ? color.withOpacity(0.4) : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasFile ? color : Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              hasFile ? color : Colors.grey.shade700,
                          fontSize: 13)),
                  if (fileName != null)
                    Text(fileName,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle : Icons.attach_file,
              color: hasFile ? color : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small reusable field label ────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
    );
  }
}
