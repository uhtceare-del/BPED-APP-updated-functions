import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_dashboard.dart';
import 'instructor_dashboard.dart';
import 'onboarding_screen.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  static const Color lnuNavy = Color(0xFF002147);
  static const Color academicGray = Color(0xFFF0F4F8);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Google Sign-Up / Sign-In ────────────────────────────────────────────────
  // Uses the same check as LoginScreen — if the account already exists in
  // Firestore, skip onboarding and go straight to the dashboard.

  Future<void> _handleGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result =
          await ref.read(authControllerProvider).signInWithGoogleAndCheck();

      if (!mounted) return;

      switch (result) {
        case GoogleSignInResult.existingUser:
          // Already registered — fetch role and go to the right dashboard
          final role = await ref
              .read(firestoreProvider)
              .collection('users')
              .doc(ref.read(authControllerProvider).currentUser!.uid)
              .get()
              .then((d) => d.data()?['role'] as String? ?? '');

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => role == 'instructor'
                  ? const InstructorDashboard()
                  : const StudentDashboard(),
            ),
            (route) => false,
          );
          break;

        case GoogleSignInResult.newUser:
          // First time — go to onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
          break;

        case GoogleSignInResult.cancelled:
          break; // user dismissed picker — do nothing

        case GoogleSignInResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Google Sign-In failed. Please try again.')),
          );
          break;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Email Sign-Up ───────────────────────────────────────────────────────────

  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: 'student',
            section: '',
            yearLevel: '',
          );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account with that email already exists. Try signing in.';
          break;
        case 'invalid-email':
          message = 'That email address is not valid.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        default:
          message = 'Sign up failed: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Unexpected error: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: academicGray,
      appBar: AppBar(
        title: const Text('Create Account',
            style: TextStyle(
                color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: lnuNavy),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school_outlined, size: 80, color: lnuNavy),
                const SizedBox(height: 24),
                const Text(
                  'Join the LNU PE Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: lnuNavy),
                ),
                const SizedBox(height: 32),

                // Google button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogle,
                  icon: const Icon(Icons.g_mobiledata,
                      color: Colors.redAccent, size: 28),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR USE EMAIL',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Gmail Address',
                    prefixIcon:
                        const Icon(Icons.email_outlined, color: lnuNavy),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.black12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your email'
                      : null,
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: lnuNavy),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.black12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 24),

                // Create with email button
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lnuNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text('CREATE WITH EMAIL',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                        color: lnuNavy, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
