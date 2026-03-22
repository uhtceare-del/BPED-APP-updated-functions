import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reviewer_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
import '../providers/class_provider.dart';

import 'student_task_detail_screen.dart';
import 'course_detail_screen.dart';
import 'login_screen.dart';
import 'offline_downloads_screen.dart';
import 'package:phys_ed/widgets/pdf_viewer_widget.dart';
import 'package:phys_ed/widgets/download_button.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  static const Color lnuNavy = Color(0xFF002147);
  static const Color academicGray = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: academicGray,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          toolbarHeight: 115,
          automaticallyImplyLeading: false,
          title: userAsync.when(
            data: (user) => _buildHeader(context, ref, user),
            loading: () =>
                const LinearProgressIndicator(color: lnuNavy),
            error: (_, _) => const Text('Error loading profile'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined,
                  color: lnuNavy),
              tooltip: 'Offline Downloads',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OfflineDownloadsScreen()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded, color: lnuNavy),
                onPressed: () => _showLogoutDialog(context, ref),
              ),
            ),
          ],
          bottom: const TabBar(
            labelColor: lnuNavy,
            unselectedLabelColor: Colors.blueGrey,
            indicatorColor: lnuNavy,
            indicatorWeight: 3,
            isScrollable: true,
            labelStyle:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Courses'),
              Tab(text: 'My Classes'),
              Tab(text: 'Tasks'),
              Tab(text: 'Reviewers'),
              Tab(text: 'Grades'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CourseBrowseTab(),
            _buildMyClasses(ref),
            _buildTaskList(ref, context),
            _buildReviewerList(ref, context),
            _buildGradesList(ref),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, WidgetRef ref, AppUser? user) {
    return GestureDetector(
      onTap: () => _showProfileModal(context, user),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: lnuNavy.withOpacity(0.1),
            backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                ? NetworkImage(user!.avatarUrl)
                : null,
            child: (user?.avatarUrl.isEmpty ?? true)
                ? const Icon(Icons.person, color: lnuNavy)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.fullName?.toUpperCase() ?? 'STUDENT',
                  style: const TextStyle(
                      color: lnuNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Section ${user?.section ?? 'N/A'} • Year ${user?.yearLevel ?? 'N/A'}',
                  style: TextStyle(
                      color: lnuNavy.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.black12),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(sub,
              style:
                  const TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }

  // ── My Classes Tab ────────────────────────────────────────────────────────────

  Widget _buildMyClasses(WidgetRef ref) {
    final classesAsync = ref.watch(myClassesProvider);
    return classesAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return _buildEmptyState(Icons.groups_outlined,
              'No classes assigned',
              'Your instructor will add you to a class section.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: lnuNavy.withOpacity(0.1),
                  child:
                      const Icon(Icons.groups, color: lnuNavy, size: 20),
                ),
                title: Text(cls.className,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${cls.subject} • ${cls.schedule}',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            );
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: lnuNavy)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ── Tasks Tab — scoped to enrolled classes ────────────────────────────────────

  Widget _buildTaskList(WidgetRef ref, BuildContext context) {
    final tasksAsync = ref.watch(allTasksProvider);
    final classIdsAsync = ref.watch(myClassIdsProvider);

    // If still loading class IDs, show spinner
    if (classIdsAsync.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: lnuNavy));
    }

    final classIds = classIdsAsync.value ?? [];
    if (classIds.isEmpty) {
      return _buildEmptyState(Icons.task_alt_outlined, 'No tasks yet',
          'You must be assigned to a class to see tasks.');
    }

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _buildEmptyState(
              Icons.task_alt, 'No tasks assigned', 'Enjoy your free time!');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final isPast = DateTime.now().isAfter(task.deadline);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isPast ? Colors.red.shade50 : Colors.green.shade50,
                  child: Icon(Icons.assignment_outlined,
                      color: isPast ? Colors.red : Colors.green,
                      size: 20),
                ),
                title: Text(task.title,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Due: ${task.deadline.month}/${task.deadline.day}/${task.deadline.year}',
                  style: TextStyle(
                      color:
                          isPast ? Colors.red : Colors.grey.shade600,
                      fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.red.withOpacity(0.08)
                        : Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPast ? 'Overdue' : 'Open',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.red : Colors.green),
                  ),
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            StudentTaskDetailScreen(task: task))),
              ),
            );
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: lnuNavy)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ── Reviewers Tab ─────────────────────────────────────────────────────────────

  Widget _buildReviewerList(WidgetRef ref, BuildContext context) {
    final reviewersAsync = ref.watch(allReviewersProvider);
    return reviewersAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return _buildEmptyState(Icons.picture_as_pdf, 'No reviewers yet',
              'Study materials will be posted here.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.picture_as_pdf,
                      color: Colors.red, size: 20),
                ),
                title: Text(doc.title,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(doc.category,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
                trailing: DownloadButton(
                  materialId: doc.id,
                  title: doc.title,
                  url: doc.fileUrl,
                  fileExtension: '.pdf',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerWidget(
                      title: doc.title,
                      urlOrPath: doc.fileUrl,
                      isOffline: false,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: lnuNavy)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ── Grades Tab ────────────────────────────────────────────────────────────────

  Widget _buildGradesList(WidgetRef ref) {
    final mySubsAsync = ref.watch(mySubmissionsProvider);
    final allTasksAsync = ref.watch(allTasksProvider);

    return mySubsAsync.when(
      data: (subs) {
        if (subs.isEmpty) {
          return _buildEmptyState(Icons.grade_outlined, 'No grades yet',
              'Submit a task to see your performance.');
        }
        return allTasksAsync.when(
          data: (tasks) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subs.length,
            itemBuilder: (context, index) {
              final sub = subs[index];
              final matchingTask = tasks.firstWhere(
                  (t) => t.id == sub.taskId,
                  orElse: () => TaskModel(
                      id: '',
                      title: 'Deleted Task',
                      description: '',
                      maxScore: 0,
                      deadline: DateTime.now()));
              final isGraded =
                  sub.grade != null && sub.grade!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: ListTile(
                  leading: Icon(Icons.star,
                      color: isGraded
                          ? Colors.amber
                          : Colors.grey.shade300),
                  title: Text(matchingTask.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Submitted: ${sub.submittedAt.month}/${sub.submittedAt.day}/${sub.submittedAt.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGraded
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isGraded
                          ? '${sub.grade}/${matchingTask.maxScore}'
                          : 'Pending',
                      style: TextStyle(
                          color: isGraded
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: lnuNavy)),
          error: (e, _) =>
              const Center(child: Text('Error matching tasks')),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: lnuNavy)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout',
            style:
                TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        content: const Text('Ready to leave the student portal?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lnuNavy),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('YES, LOGOUT',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProfileModal(BuildContext context, AppUser? user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('STUDENT PROFILE',
                  style: TextStyle(
                      color: lnuNavy,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const Divider(height: 30),
              CircleAvatar(
                radius: 45,
                backgroundColor: academicGray,
                backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                    ? NetworkImage(user!.avatarUrl)
                    : null,
                child: (user?.avatarUrl.isEmpty ?? true)
                    ? const Icon(Icons.person, size: 40, color: lnuNavy)
                    : null,
              ),
              const SizedBox(height: 20),
              _profileRow(
                  Icons.person_outline, 'Name', user?.fullName ?? 'N/A'),
              _profileRow(
                  Icons.email_outlined, 'Email', user?.email ?? 'N/A'),
              _profileRow(Icons.class_outlined, 'Section',
                  user?.section ?? 'N/A'),
              _profileRow(Icons.trending_up, 'Year',
                  '${user?.yearLevel ?? 'N/A'} Year'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CLOSE',
                      style: TextStyle(
                          color: lnuNavy, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: lnuNavy.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black54)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: lnuNavy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Course Browse + Enroll Tab ────────────────────────────────────────────────
// Separate StatefulWidget so it can manage its own loading state per card.

class _CourseBrowseTab extends ConsumerWidget {
  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allCoursesProvider);
    final enrolledAsync = ref.watch(enrolledCoursesProvider);
    final userAsync = ref.watch(currentUserProvider);

    final studentId = userAsync.value?.uid ?? '';
    final enrolledIds = enrolledAsync.value?.map((c) => c.id).toSet() ?? {};

    return allAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_outlined,
                    size: 60, color: Colors.black12),
                SizedBox(height: 16),
                Text('No courses available yet.',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('Check back later.',
                    style:
                        TextStyle(color: Colors.black38, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final isEnrolled = enrolledIds.contains(course.id);

            return _CourseCard(
              course: course,
              isEnrolled: isEnrolled,
              studentId: studentId,
            );
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: lnuNavy)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _CourseCard extends ConsumerStatefulWidget {
  final CourseModel course;
  final bool isEnrolled;
  final String studentId;

  const _CourseCard({
    required this.course,
    required this.isEnrolled,
    required this.studentId,
  });

  @override
  ConsumerState<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends ConsumerState<_CourseCard> {
  static const Color lnuNavy = Color(0xFF002147);
  bool _loading = false;

  Future<void> _toggle() async {
    if (widget.studentId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(courseRepositoryProvider);
      if (widget.isEnrolled) {
        await repo.unenrollStudent(
            courseId: widget.course.id, studentId: widget.studentId);
      } else {
        await repo.enrollStudent(
            courseId: widget.course.id, studentId: widget.studentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isEnrolled
              ? lnuNavy.withOpacity(0.4)
              : Colors.black12,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.isEnrolled
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CourseDetailScreen(course: widget.course)),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.isEnrolled
                      ? lnuNavy.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.fitness_center,
                    color:
                        widget.isEnrolled ? lnuNavy : Colors.grey,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.course.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: widget.isEnrolled
                                ? lnuNavy
                                : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(
                      widget.course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                    if (widget.isEnrolled) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 13,
                              color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text('Enrolled',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('Tap to view lessons',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: lnuNavy))
                  : widget.isEnrolled
                      ? OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _toggle,
                          child: const Text('Drop',
                              style: TextStyle(fontSize: 12)),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lnuNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _toggle,
                          child: const Text('Enroll',
                              style: TextStyle(fontSize: 12)),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
