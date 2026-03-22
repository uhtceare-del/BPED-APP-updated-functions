import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'task_screen.dart';
import 'lesson_screen.dart';
import 'class_screen.dart';
import 'reviewer_screen.dart';
import 'submission_screen.dart';

final selectedModuleProvider = StateProvider<int>((ref) => 0);

class InstructorDashboard extends ConsumerWidget {
  const InstructorDashboard({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  static const _labels = [
    'Tasks', 'Lessons', 'Classes', 'Reviewers', 'Submissions',
  ];
  static const _icons = [
    Icons.task_outlined,
    Icons.menu_book_outlined,
    Icons.groups_outlined,
    Icons.upload_file_outlined,
    Icons.assignment_outlined,
  ];
  static const _activeIcons = [
    Icons.task,
    Icons.menu_book,
    Icons.groups,
    Icons.upload_file,
    Icons.assignment_turned_in,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedModuleProvider);
    final userAsync = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    final screens = [
      const TaskScreen(),
      const LessonScreen(),
      const ClassScreen(),
      const ReviewerScreen(),
      const SubmissionScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        toolbarHeight: 115,
        automaticallyImplyLeading: false,
        title: userAsync.when(
          data: (user) => _buildHeader(context, ref, user),
          loading: () => const SizedBox(
              height: 3, child: LinearProgressIndicator(color: lnuNavy)),
          error: (_, _) => const Text('Error'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: screenWidth < 700
              ? SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _labels.length,
                    itemBuilder: (_, i) =>
                        _buildTabChip(ref, i, selectedIndex),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: screenWidth >= 700
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) =>
                      ref.read(selectedModuleProvider.notifier).state = i,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme:
                      const IconThemeData(color: lnuNavy),
                  selectedLabelTextStyle: const TextStyle(
                      color: lnuNavy, fontWeight: FontWeight.bold),
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
                    child: screens[selectedIndex],
                  ),
                ),
              ],
            )
          : screens[selectedIndex],
      bottomNavigationBar: screenWidth < 700
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (i) =>
                  ref.read(selectedModuleProvider.notifier).state = i,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: lnuNavy,
              unselectedItemColor: Colors.grey,
              items: List.generate(
                _labels.length,
                (i) => BottomNavigationBarItem(
                  icon: Icon(_icons[i]),
                  activeIcon: Icon(_activeIcons[i]),
                  label: _labels[i],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTabChip(WidgetRef ref, int i, int selectedIndex) {
    final isSelected = selectedIndex == i;
    return GestureDetector(
      onTap: () => ref.read(selectedModuleProvider.notifier).state = i,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? lnuNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? lnuNavy : Colors.grey.shade300),
        ),
        child: Text(
          _labels[i],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, appUser) {
    return GestureDetector(
      onTap: () => _showProfileModal(context, appUser),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: lnuNavy.withOpacity(0.1),
            backgroundImage:
                ((appUser?.avatarUrl as String?)?.isNotEmpty ?? false)
                    ? NetworkImage(appUser!.avatarUrl as String)
                    : null,
            child: ((appUser?.avatarUrl as String?)?.isEmpty ?? true)
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
                  ((appUser?.fullName as String?)?.toUpperCase()) ??
                      'INSTRUCTOR',
                  style: const TextStyle(
                      color: lnuNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Instructor · LNU PE Department',
                  style: TextStyle(
                      color: lnuNavy.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: lnuNavy),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showProfileModal(BuildContext context, appUser) {
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
              const Text('INSTRUCTOR PROFILE',
                  style: TextStyle(
                      color: lnuNavy,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const Divider(height: 30),
              CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFF8FAFC),
                backgroundImage:
                    ((appUser?.avatarUrl as String?)?.isNotEmpty ?? false)
                        ? NetworkImage(appUser!.avatarUrl as String)
                        : null,
                child: ((appUser?.avatarUrl as String?)?.isEmpty ?? true)
                    ? const Icon(Icons.person, size: 40, color: lnuNavy)
                    : null,
              ),
              const SizedBox(height: 20),
              _profileRow(Icons.person_outline, 'Name',
                  (appUser?.fullName as String?) ?? 'N/A'),
              _profileRow(Icons.email_outlined, 'Email',
                  (appUser?.email as String?) ?? 'N/A'),
              _profileRow(Icons.badge_outlined, 'Role', 'Instructor'),
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout',
            style:
                TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        content: const Text('Ready to leave the instructor portal?'),
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
            },
            child: const Text('YES, LOGOUT',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
