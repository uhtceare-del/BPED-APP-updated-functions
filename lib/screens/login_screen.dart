import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'signup_screen.dart';
import 'student_dashboard.dart';
import 'instructor_dashboard.dart';
import 'admin_dashboard.dart';
import 'onboarding_screen.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const Color lnuNavy = Color(0xFF002147);
  static const Color lnuMaroon = Color(0xFF800000);

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

  // ── Google Sign-In ──────────────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result =
          await ref.read(authControllerProvider).signInWithGoogleAndCheck();

      if (!mounted) return;

      switch (result) {
        case GoogleSignInResult.existingUser:
          // Fetch role then navigate directly — no reliance on AuthWrapper
          final uid = ref.read(authControllerProvider).currentUser?.uid;
          if (uid == null) return;

          final doc = await ref
              .read(firestoreProvider)
              .collection('users')
              .doc(uid)
              .get();
          final role = doc.data()?['role'] as String? ?? '';

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
                content: Text('Google Sign-In failed. Please try again.')),
          );
          break;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Email / Password Sign-In ────────────────────────────────────────────────

  Future<void> _login() async {
    // ── Hardcoded admin bypass — checked BEFORE validation or Firebase ──────
    if (_emailController.text.trim() == 'admin' &&
        _passwordController.text.trim() == 'admin') {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
        (route) => false,
      );
      return;
    }
    // ───────────────────────────────────────────────────────────────────────

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await ref.read(authControllerProvider).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (!userCredential.user!.emailVerified) {
        await ref.read(authControllerProvider).signOut();
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showUnverifiedDialog(userCredential.user!);
        return;
      }

      final userDoc = await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      final role = userDoc.data()?['role'] as String? ?? 'student';

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
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
          message = 'No account found with that email address.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect password. Please try again.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled. Contact support.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please wait and try again.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: lnuMaroon),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Unexpected error: $e'),
              backgroundColor: lnuMaroon),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showUnverifiedDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email Not Verified',
            style: TextStyle(color: lnuMaroon, fontWeight: FontWeight.bold)),
        content: const Text(
            'Check your Gmail inbox and click the verification link before logging in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Close', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lnuNavy),
            onPressed: () async {
              await ref
                  .read(authControllerProvider)
                  .resendVerificationEmail(user);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Resend Link',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo — bundled asset with network fallback ──────────────
                  Image.asset(
                    'assets/lnu.png',
                    height: 120,
                    errorBuilder: (_, _, _) => const Icon(
                        Icons.school,
                        size: 80,
                        color: lnuNavy),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'BPED MANAGEMENT SYSTEM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: lnuNavy,
                        letterSpacing: 1.1),
                  ),
                  const Text(
                    'Leyte Normal University',
                    style: TextStyle(
                        fontSize: 14,
                        color: lnuMaroon,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 48),

                  // ── Email field ─────────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email / Username',
                      prefixIcon:
                          const Icon(Icons.email_outlined, color: lnuNavy),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: lnuNavy, width: 2),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter your email or username' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Password field ──────────────────────────────────────────
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
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: lnuNavy, width: 2),
                      ),
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
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Password required' : null,
                  ),
                  const SizedBox(height: 32),

                  // ── Sign In button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lnuNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('SIGN IN',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Google button ───────────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata,
                        color: Colors.redAccent, size: 28),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: Colors.white,
                      side:
                          const BorderSide(color: Colors.grey, width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Sign-up link ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                              color: lnuMaroon,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
