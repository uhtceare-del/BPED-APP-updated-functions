import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'student_dashboard.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedYear;
  String? _selectedSection;
  bool _isSaving = false;

  static const Color lnuNavy = Color(0xFF002147);
  static const Color lnuMaroon = Color(0xFF800000);

  final Map<String, List<String>> _yearToSections = {
    '1': ['PE-11', 'PE-12', 'PE-13', 'PE-14'],
    '2': ['PE-21', 'PE-22', 'PE-23', 'PE-24'],
    '3': ['PE-31', 'PE-32', 'PE-33', 'PE-34'],
    '4': ['PE-41', 'PE-42', 'PE-43', 'PE-44'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile Setup',
            style:
                TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/lnu.png',
                        height: 80,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.school, size: 80, color: lnuNavy)),
                    const SizedBox(height: 16),
                    const Text('Welcome to LNU PE Portal!',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: lnuNavy)),
                    const SizedBox(height: 4),
                    const Text('Complete your student profile to continue.',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Full Name
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 20),

              // Year Level
              DropdownButtonFormField<String>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trending_up),
                ),
                items: _yearToSections.keys
                    .map((y) => DropdownMenuItem(
                        value: y, child: Text('Year $y')))
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (v) => setState(() {
                          _selectedYear = v;
                          _selectedSection = null;
                        }),
                validator: (v) =>
                    v == null ? 'Select your year level' : null,
              ),
              const SizedBox(height: 20),

              // Section
              DropdownButtonFormField<String>(
                initialValue: _selectedSection,
                disabledHint: const Text('Select Year Level first'),
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_outlined),
                ),
                items: _selectedYear == null
                    ? []
                    : _yearToSections[_selectedYear]!
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: _isSaving
                    ? null
                    : (v) => setState(() => _selectedSection = v),
                validator: (v) => v == null ? 'Select your section' : null,
              ),
              const SizedBox(height: 40),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lnuNavy,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('COMPLETE SETUP',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = ref.read(authControllerProvider).currentUser;
      if (user == null) return;

      await ref.read(authRepositoryProvider).completeOnboarding(
        uid: user.uid,
        fullName: _nameController.text.trim(),
        role: 'student', // always student — instructors are set via Firebase console
        yearLevel: _selectedYear!,
        section: _selectedSection!,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
