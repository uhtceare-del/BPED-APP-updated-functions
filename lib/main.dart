import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/instructor_dashboard.dart';
import 'screens/admin_dashboard.dart';

// Providers
import 'providers/auth_provider.dart';

// Hive models
import 'models/offline_material_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // google_sign_in v7: initialize() must be called ONCE here at app startup.
  // Calling it inside the sign-in flow on every tap causes an infinite loop.
  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }

  // Hive offline storage
  await Hive.initFlutter();
  Hive.registerAdapter(OfflineMaterialAdapter());
  await Hive.openBox('downloadsBox');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhysEdLearn',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF002147),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF002147),
          primary: const Color(0xFF002147),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();

        return ref
            .watch(currentUserProvider)
            .when(
              data: (appUser) {
                if (appUser == null) return const OnboardingScreen();
                if (!appUser.onboardingCompleted)
                  return const OnboardingScreen();
                if (appUser.role.isEmpty) return const OnboardingScreen();

                switch (appUser.role) {
                  case 'admin':
                    return const AdminDashboard();
                  case 'instructor':
                    return const InstructorDashboard();
                  case 'student':
                    final incomplete =
                        (appUser.section?.isEmpty ?? true) ||
                        (appUser.yearLevel?.isEmpty ?? true);
                    if (incomplete) return const OnboardingScreen();
                    return const StudentDashboard();
                  default:
                    return const OnboardingScreen();
                }
              },
              loading: () => const _LoadingScaffold(),
              error: (e, _) => _ErrorScaffold(message: 'Profile Error: $e'),
            );
      },
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(message: 'Auth Error: $e'),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Color(0xFF002147))),
  );
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(message)));
}
