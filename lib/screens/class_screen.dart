import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';

class ClassScreen extends ConsumerWidget {
  const ClassScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(allClassesProvider);

    return Scaffold(
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No sections created yet.',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Text('Tap the button below to add one.',
                      style: TextStyle(color: Colors.black38, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final section = classes[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: lnuNavy.withOpacity(0.1),
                    child: const Icon(Icons.groups, color: lnuNavy, size: 20),
                  ),
                  title: Text(section.className,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: lnuNavy)),
                  subtitle: Text('${section.subject} • ${section.schedule}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Chip(
                    label: Text('${section.enrolledStudentIds.length} students',
                        style: const TextStyle(fontSize: 11, color: lnuNavy)),
                    backgroundColor: lnuNavy.withOpacity(0.08),
                    padding: EdgeInsets.zero,
                  ),
                  onTap: () => _showClassDetail(context, ref, section),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: lnuNavy,
        onPressed: () => _showAddClassDialog(context, ref),
        label: const Text('Add Section', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Class Detail Sheet ──────────────────────────────────────────────────────

  void _showClassDetail(BuildContext context, WidgetRef ref, ClassModel section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, scrollController) => _ClassDetailSheet(
          section: section,
          scrollController: scrollController,
        ),
      ),
    );
  }

  // ── Add Section Dialog ──────────────────────────────────────────────────────

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final schedController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Section',
            style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Class Name (e.g. BPED 1A)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: schedController,
              decoration: const InputDecoration(
                labelText: 'Schedule (e.g. Mon/Wed 1:00PM)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lnuNavy),
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final newClass = ClassModel(
                id: '',
                className: nameController.text.trim(),
                subject: subjectController.text.trim(),
                schedule: schedController.text.trim(),
              );
              await ref.read(classRepositoryProvider).createClass(newClass);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Class Detail Sheet Widget ───────────────────────────────────────────────

class _ClassDetailSheet extends ConsumerWidget {
  final ClassModel section;
  final ScrollController scrollController;

  const _ClassDetailSheet({
    required this.section,
    required this.scrollController,
  });

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsInClassProvider(section.id));
    final allStudentsAsync = ref.watch(studentsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text(section.className,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: lnuNavy)),
          Text('${section.subject} • ${section.schedule}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 4),

          // Enroll student button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showEnrollDialog(context, ref, allStudentsAsync.value ?? []),
              icon: const Icon(Icons.person_add_alt_1, size: 18, color: lnuNavy),
              label: const Text('Enroll Student',
                  style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
            ),
          ),

          const Divider(),
          const Text('Enrolled Students',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),

          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return const Center(
                    child: Text('No students enrolled yet.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final student = students[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: lnuNavy.withOpacity(0.1),
                        backgroundImage: student.avatarUrl.isNotEmpty
                            ? NetworkImage(student.avatarUrl)
                            : null,
                        child: student.avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: lnuNavy, size: 18)
                            : null,
                      ),
                      title: Text(student.fullName ?? student.email,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Yr ${student.yearLevel ?? '?'} • Sec ${student.section ?? '?'}',
                          style: const TextStyle(fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red, size: 20),
                        tooltip: 'Remove from class',
                        onPressed: () async {
                          await ref
                              .read(classRepositoryProvider)
                              .unenrollStudent(
                              classId: section.id,
                              studentId: student.uid);
                          // Invalidate so the sheet refreshes
                          ref.invalidate(studentsInClassProvider(section.id));
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnrollDialog(
      BuildContext context, WidgetRef ref, List<AppUser> allStudents) {
    // Filter out already-enrolled students
    final available = allStudents
        .where((s) => !section.enrolledStudentIds.contains(s.uid))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All students are already enrolled.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enroll a Student',
            style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (_, i) {
              final student = available[i];
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(student.fullName ?? student.email),
                subtitle: Text('Yr ${student.yearLevel ?? '?'} • ${student.section ?? '?'}'),
                onTap: () async {
                  await ref.read(classRepositoryProvider).enrollStudent(
                    classId: section.id,
                    studentId: student.uid,
                  );
                  ref.invalidate(studentsInClassProvider(section.id));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );
  }
}