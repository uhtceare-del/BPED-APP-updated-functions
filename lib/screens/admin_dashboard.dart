import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/class_provider.dart';
import '../models/course_model.dart';
import '../providers/admin_provider.dart';
import 'login_screen.dart';

const _lnuNavy = Color(0xFF002147);
const _lnuMaroon = Color(0xFF800000);

final _adminTabProvider = StateProvider<int>((ref) => 0);

// ══════════════════════════════════════════════════════════════════
// SHELL
// ══════════════════════════════════════════════════════════════════

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  static const _labels = ['Courses', 'Reports', 'Users', 'Uploads'];
  static const _icons = [
    Icons.library_books_outlined,
    Icons.bar_chart_outlined,
    Icons.people_outline,
    Icons.upload_file_outlined,
  ];
  static const _activeIcons = [
    Icons.library_books,
    Icons.bar_chart,
    Icons.people,
    Icons.upload_file,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_adminTabProvider);
    final wide = MediaQuery.of(context).size.width >= 700;
    final screens = [
      const _CoursesTab(),
      const _ReportsTab(),
      const _UsersTab(),
      const _UploadsTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        toolbarHeight: 115,
        automaticallyImplyLeading: false,
        title: ref
            .watch(currentUserProvider)
            .when(
              data: (u) => _Header(u),
              loading: () => const LinearProgressIndicator(color: _lnuNavy),
              error: (_, __) => const Text('Error'),
            ),
        bottom: wide
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _TabChips(
                  labels: _labels,
                  selected: tab,
                  onTap: (i) => ref.read(_adminTabProvider.notifier).state = i,
                ),
              ),
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: tab,
                  onDestinationSelected: (i) =>
                      ref.read(_adminTabProvider.notifier).state = i,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: _lnuNavy),
                  selectedLabelTextStyle: const TextStyle(
                    color: _lnuNavy,
                    fontWeight: FontWeight.bold,
                  ),
                  destinations: List.generate(
                    _labels.length,
                    (i) => NavigationRailDestination(
                      icon: Icon(_icons[i]),
                      selectedIcon: Icon(_activeIcons[i]),
                      label: Text(_labels[i]),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: screens[tab],
                  ),
                ),
              ],
            )
          : screens[tab],
      bottomNavigationBar: wide
          ? null
          : BottomNavigationBar(
              currentIndex: tab,
              onTap: (i) => ref.read(_adminTabProvider.notifier).state = i,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: _lnuNavy,
              unselectedItemColor: Colors.grey,
              items: List.generate(
                _labels.length,
                (i) => BottomNavigationBarItem(
                  icon: Icon(_icons[i]),
                  activeIcon: Icon(_activeIcons[i]),
                  label: _labels[i],
                ),
              ),
            ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final dynamic appUser;
  const _Header(this.appUser);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _lnuMaroon.withOpacity(0.15),
          child: const Icon(Icons.admin_panel_settings, color: _lnuMaroon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ((appUser?.fullName as String?)?.toUpperCase()) ?? 'ADMIN',
                style: const TextStyle(
                  color: _lnuNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Administrator · LNU PE Department',
                style: TextStyle(
                  color: _lnuMaroon.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: _lnuNavy),
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(
                'Logout',
                style: TextStyle(color: _lnuNavy, fontWeight: FontWeight.bold),
              ),
              content: const Text('Sign out of the admin portal?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _lnuNavy),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(authControllerProvider).signOut();
                    if (context.mounted)
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false,
                      );
                  },
                  child: const Text(
                    'YES, LOGOUT',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab chips ─────────────────────────────────────────────────────

class _TabChips extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onTap;
  const _TabChips({
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: labels.length,
        itemBuilder: (_, i) {
          final sel = selected == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _lnuNavy : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? _lnuNavy : Colors.grey.shade300,
                ),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: sel ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// COURSES TAB
// ══════════════════════════════════════════════════════════════════

class _CoursesTab extends ConsumerWidget {
  const _CoursesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: coursesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _lnuNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (courses) => courses.isEmpty
            ? const _EmptyState(
                icon: Icons.library_books_outlined,
                title: 'No courses yet.',
                sub: 'Tap the button below to add your first course.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (_, i) => _CourseCard(
                  course: courses[i],
                  onEdit: () => _courseSheet(context, ref, courses[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _lnuNavy,
        label: const Text(
          'New Course',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _courseSheet(context, ref),
      ),
    );
  }

  void _courseSheet(
    BuildContext context,
    WidgetRef ref, [
    CourseModel? existing,
  ]) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final descCtrl = TextEditingController(text: existing?.description);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormSheet(
        title: existing == null ? 'Create New Course' : 'Edit Course',
        fields: [
          _OutlineField(nameCtrl, 'Course Name'),
          const SizedBox(height: 12),
          _OutlineField(descCtrl, 'Description', maxLines: 3),
          const SizedBox(height: 12),
        ],
        buttonLabel: existing == null ? 'CREATE COURSE' : 'SAVE CHANGES',
        buttonColor: existing == null ? _lnuNavy : Colors.blueAccent,
        onSubmit: () async {
          if (nameCtrl.text.trim().isEmpty) throw Exception('Name required.');
          final repo = ref.read(courseRepositoryProvider);
          existing == null
              ? await repo.createCourse(
                  CourseModel(
                    id: '',
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    enrolledStudents: const [],
                  ),
                )
              : await repo.updateCourse(existing.id, {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                });
        },
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  final CourseModel course;
  final VoidCallback onEdit;
  const _CourseCard({required this.course, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _lnuNavy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.school_outlined, color: _lnuNavy),
        ),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _lnuNavy),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 13,
                  color: Colors.blueGrey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  '${course.enrolledStudents.length} enrolled',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _ConfirmDialog(
                  title: 'Delete Course',
                  content: "Delete '${course.name}'?",
                  onConfirm: () => ref
                      .read(courseRepositoryProvider)
                      .deleteCourse(course.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// REPORTS TAB
// ══════════════════════════════════════════════════════════════════

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Colors.blueGrey,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminSummaryProvider);
    final grades = ref.watch(adminGradesProvider);
    final classes = ref.watch(allClassesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('OVERVIEW'),
          const SizedBox(height: 12),
          summary.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (d) => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _StatCard(
                  'Total Students',
                  d['students']!,
                  Icons.people_outline,
                  Colors.blue,
                ),
                _StatCard(
                  'Total Courses',
                  d['courses']!,
                  Icons.library_books_outlined,
                  Colors.green,
                ),
                _StatCard(
                  'Total Tasks',
                  d['tasks']!,
                  Icons.assignment_outlined,
                  Colors.orange,
                ),
                _StatCard(
                  'Submissions',
                  d['submissions']!,
                  Icons.upload_file_outlined,
                  Colors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _label('STUDENTS PER CLASS'),
          const SizedBox(height: 12),
          classes.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (list) => Column(
              children: list
                  .map(
                    (cls) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _lnuNavy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.groups,
                              color: _lnuNavy,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cls.className,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  cls.subject,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${cls.enrolledStudentIds.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: _lnuNavy,
                                ),
                              ),
                              const Text(
                                'students',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 28),
          _label('GRADE DISTRIBUTION'),
          const SizedBox(height: 12),
          grades.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (buckets) {
              final total = buckets.values.fold(0, (a, b) => a + b);
              if (total == 0)
                return const Text(
                  'No graded submissions yet.',
                  style: TextStyle(color: Colors.grey),
                );
              final colors = [
                Colors.green,
                Colors.lightGreen,
                Colors.orange,
                Colors.deepOrange,
                Colors.red,
              ];
              final keys = ['90-100', '75-89', '60-74', '50-59', 'Below 50'];
              return Column(
                children: List.generate(keys.length, (i) {
                  final count = buckets[keys[i]] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              keys[i],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '$count student${count == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? count / total : 0.0,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation(colors[i]),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
// USERS TAB
// ══════════════════════════════════════════════════════════════════

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();
  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  String _search = '';
  String _roleFilter = 'all';
  final _roles = ['all', 'student', 'instructor', 'admin'];

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> u) => u.where((
    u,
  ) {
    final n = (u['fullName'] ?? '').toString().toLowerCase();
    final e = (u['email'] ?? '').toString().toLowerCase();
    final r = (u['role'] ?? '').toString().toLowerCase();
    return (_search.isEmpty || n.contains(_search) || e.contains(_search)) &&
        (_roleFilter == 'all' || r == _roleFilter);
  }).toList();

  void openSheet([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    final uid = existing?['id'] as String?;
    final nameCtrl = TextEditingController(
      text: (existing?['fullName'] ?? '').toString(),
    );
    final emailCtrl = TextEditingController(
      text: (existing?['email'] ?? '').toString(),
    );
    final yearCtrl = TextEditingController(
      text: (existing?['yearLevel'] ?? '').toString(),
    );
    final sectionCtrl = TextEditingController(
      text: (existing?['section'] ?? '').toString(),
    );
    String role = (existing?['role'] ?? 'student').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 28,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHandle(),
                const SizedBox(height: 20),
                Text(
                  isEdit ? 'Edit User' : 'Create New User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _lnuNavy,
                  ),
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Creates a profile. User must use "Forgot Password" to activate.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 20),
                _OutlineField(
                  nameCtrl,
                  'Full Name',
                  caps: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _OutlineField(
                  emailCtrl,
                  'Email Address',
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                _RolePicker(
                  selected: role,
                  onChanged: (r) => setSheet(() => role = r),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OutlineField(yearCtrl, 'Year Level (optional)'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OutlineField(sectionCtrl, 'Section (optional)'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SubmitButton(
                  label: isEdit ? 'SAVE CHANGES' : 'CREATE USER',
                  color: isEdit ? Colors.blueAccent : _lnuNavy,
                  onSubmit: () async {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    if (name.isEmpty || email.isEmpty) {
                      throw Exception('Name and email are required.');
                    }
                    final data = {
                      'fullName': name,
                      'email': email,
                      'role': role,
                      'yearLevel': yearCtrl.text.trim(),
                      'section': sectionCtrl.text.trim(),
                    };
                    isEdit
                        ? await adminUpdateUser(uid!, data)
                        : await adminCreateUser({
                            ...data,
                            'avatarUrl': '',
                            'onboardingCompleted': true,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: const Icon(Icons.search, color: _lnuNavy),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roles.map((r) {
                      final sel = _roleFilter == r;
                      return GestureDetector(
                        onTap: () => setState(() => _roleFilter = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? _lnuNavy : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? _lnuNavy : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            r == 'all'
                                ? 'All'
                                : r[0].toUpperCase() + r.substring(1),
                            style: TextStyle(
                              color: sel ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _lnuNavy),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final users = _filter(all);
                if (users.isEmpty)
                  return const _EmptyState(
                    icon: Icons.people_outline,
                    title: 'No users found.',
                  );
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: users.length,
                  itemBuilder: (_, i) => _UserCard(
                    user: users[i],
                    onEdit: () => openSheet(users[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _lnuNavy,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Create User',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => openSheet(),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  const _UserCard({required this.user, required this.onEdit});

  static Color _rc(String r) => switch (r.toLowerCase()) {
    'admin' => Colors.deepPurple,
    'instructor' => Colors.blue,
    _ => Colors.teal,
  };
  static IconData _ri(String r) => switch (r.toLowerCase()) {
    'admin' => Icons.admin_panel_settings,
    'instructor' => Icons.school,
    _ => Icons.person,
  };

  @override
  Widget build(BuildContext context) {
    final uid = user['id'] as String;
    final name = (user['fullName'] ?? 'No name').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? 'student').toString();
    final section = (user['section'] ?? '').toString();
    final year = (user['yearLevel'] ?? '').toString();
    final avatar = (user['avatarUrl'] ?? '').toString();
    final rc = _rc(role);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: rc.withOpacity(0.12),
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar.isEmpty ? Icon(_ri(role), color: rc, size: 20) : null,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: _lnuNavy,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _RoleBadge(role: role, color: rc),
                if (section.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Yr $year • $section',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.blueAccent,
                size: 20,
              ),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _ConfirmDialog(
                  title: 'Delete User',
                  content: "Delete '$name'? This removes their profile.",
                  onConfirm: () => adminDeleteUser(uid),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// UPLOADS TAB
// ══════════════════════════════════════════════════════════════════

class _UploadsTab extends ConsumerStatefulWidget {
  const _UploadsTab();
  @override
  ConsumerState<_UploadsTab> createState() => _UploadsTabState();
}

class _UploadsTabState extends ConsumerState<_UploadsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _editSheet(
    BuildContext ctx,
    String title,
    List<Widget> fields,
    Future<void> Function() onSave,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormSheet(
        title: title,
        fields: fields,
        buttonLabel: 'SAVE CHANGES',
        buttonColor: Colors.blueAccent,
        onSubmit: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(adminLessonsProvider);
    final reviewers = ref.watch(adminReviewersProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabs,
          labelColor: _lnuNavy,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _lnuNavy,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Lessons'),
            Tab(icon: Icon(Icons.picture_as_pdf_outlined), text: 'Reviewers'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              // Lessons
              lessons.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _lnuNavy),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) => list.isEmpty
                    ? const _EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'No lessons uploaded yet.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final l = list[i];
                          final tCtrl = TextEditingController(
                            text: l['title']?.toString(),
                          );
                          final dCtrl = TextEditingController(
                            text: l['description']?.toString(),
                          );
                          final cCtrl = TextEditingController(
                            text: l['category']?.toString(),
                          );
                          return _UploadCard(
                            icon: Icons.menu_book,
                            iconBg: _lnuNavy.withOpacity(0.08),
                            iconColor: _lnuNavy,
                            title: (l['title'] ?? 'Untitled').toString(),
                            subtitle: (l['category'] ?? '').toString(),
                            chips: [
                              if ((l['videoUrl'] ?? '').toString().isNotEmpty)
                                const _MiniChip('Video', Colors.blue),
                              if ((l['pdfUrl'] ?? '').toString().isNotEmpty)
                                const _MiniChip('PDF', Colors.red),
                              if ((l['audioUrl'] ?? '').toString().isNotEmpty)
                                const _MiniChip('Audio', Colors.purple),
                            ],
                            onEdit: () => _editSheet(
                              context,
                              'Edit Lesson',
                              [
                                _OutlineField(tCtrl, 'Title'),
                                const SizedBox(height: 12),
                                _OutlineField(
                                  dCtrl,
                                  'Description',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 12),
                                _OutlineField(cCtrl, 'Category'),
                                const SizedBox(height: 12),
                              ],
                              () => adminUpdateLesson(l['id'] as String, {
                                'title': tCtrl.text.trim(),
                                'description': dCtrl.text.trim(),
                                'category': cCtrl.text.trim(),
                              }),
                            ),
                            onDelete: () => showDialog(
                              context: context,
                              builder: (_) => _ConfirmDialog(
                                title: 'Delete Lesson',
                                content: "Delete '${l['title']}'?",
                                onConfirm: () =>
                                    adminDeleteLesson(l['id'] as String),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Reviewers
              reviewers.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _lnuNavy),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) => list.isEmpty
                    ? const _EmptyState(
                        icon: Icons.picture_as_pdf_outlined,
                        title: 'No reviewers uploaded yet.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final r = list[i];
                          final tCtrl = TextEditingController(
                            text: r['title']?.toString(),
                          );
                          final cCtrl = TextEditingController(
                            text: r['category']?.toString(),
                          );
                          return _UploadCard(
                            icon: Icons.picture_as_pdf,
                            iconBg: Colors.red.shade50,
                            iconColor: Colors.red,
                            title: (r['title'] ?? 'Untitled').toString(),
                            subtitle: (r['category'] ?? '').toString(),
                            chips: const [],
                            onEdit: () => _editSheet(
                              context,
                              'Edit Reviewer',
                              [
                                _OutlineField(tCtrl, 'Title'),
                                const SizedBox(height: 12),
                                _OutlineField(cCtrl, 'Category'),
                                const SizedBox(height: 12),
                              ],
                              () => adminUpdateReviewer(r['id'] as String, {
                                'title': tCtrl.text.trim(),
                                'category': cCtrl.text.trim(),
                              }),
                            ),
                            onDelete: () => showDialog(
                              context: context,
                              builder: (_) => _ConfirmDialog(
                                title: 'Delete Reviewer',
                                content: "Delete '${r['title']}'?",
                                onConfirm: () =>
                                    adminDeleteReviewer(r['id'] as String),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final List<Widget> chips;
  final VoidCallback onEdit, onDelete;
  const _UploadCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: _lnuNavy),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(spacing: 4, children: chips),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.blueAccent,
              size: 20,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
// SHARED MICRO-WIDGETS
// ══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  const _EmptyState({required this.icon, required this.title, this.sub});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (sub != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              sub!,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
      ],
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String title, content;
  final Future<void> Function() onConfirm;
  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.redAccent,
        fontWeight: FontWeight.bold,
      ),
    ),
    content: Text(content),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        onPressed: () async {
          Navigator.pop(context);
          await onConfirm();
        },
        child: const Text('DELETE', style: TextStyle(color: Colors.white)),
      ),
    ],
  );
}

class _FormSheet extends StatelessWidget {
  final String title, buttonLabel;
  final Color buttonColor;
  final List<Widget> fields;
  final Future<void> Function() onSubmit;
  const _FormSheet({
    required this.title,
    required this.fields,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => Padding(
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
        _SheetHandle(),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _lnuNavy,
          ),
        ),
        const SizedBox(height: 16),
        ...fields,
        _SubmitButton(
          label: buttonLabel,
          color: buttonColor,
          onSubmit: onSubmit,
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class _SubmitButton extends StatefulWidget {
  final String label;
  final Color color;
  final Future<void> Function() onSubmit;
  const _SubmitButton({
    required this.label,
    required this.color,
    required this.onSubmit,
  });
  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onSubmit();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                setState(() => _loading = false);
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
      child: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _OutlineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboard;
  final TextCapitalization caps;
  const _OutlineField(
    this.controller,
    this.label, {
    this.maxLines = 1,
    this.keyboard,
    this.caps = TextCapitalization.sentences,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboard,
    textCapitalization: caps,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}

class _RolePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _RolePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    children: ['student', 'instructor', 'admin'].map((r) {
      final sel = selected == r;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? _lnuNavy : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? _lnuNavy : Colors.grey.shade300),
            ),
            child: Text(
              r[0].toUpperCase() + r.substring(1),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: sel ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final Color color;
  const _RoleBadge({required this.role, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      role[0].toUpperCase() + role.substring(1),
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
    ),
  );
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
    ),
  );
}
