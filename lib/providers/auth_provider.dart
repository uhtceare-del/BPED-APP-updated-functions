import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(authState.uid)
      .snapshots()
      .map((snap) => snap.exists
          ? AppUser.fromFirestore(snap.data()!, authState.uid)
          : null);
});

// ── Result type ───────────────────────────────────────────────────────────────

enum GoogleSignInResult {
  existingUser,
  newUser,
  cancelled,
  error,
}

// ── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository(this.auth, this.firestore);

  /// Google sign-in — correct for google_sign_in v7.x
  ///
  /// v7 key facts:
  ///   • GoogleSignIn.instance      — static singleton, no constructor
  ///   • initialize()               — called ONCE in main(), NOT here
  ///   • authenticate()             — async, shows account picker
  ///   • googleUser.authentication  — SYNC getter, do NOT await
  ///   • .idToken                   — only token available; accessToken removed
  ///   • GoogleSignInException      — e.code, e.description (no .message)
  Future<GoogleSignInResult> signInWithGoogleAndCheck() async {
    try {
      UserCredential credential;

      if (kIsWeb) {
        // ── Web: firebase_auth popup ──────────────────────────────────────────
        final googleProvider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        credential = await auth.signInWithPopup(googleProvider);
      } else {
        // ── Mobile: google_sign_in v7 ─────────────────────────────────────────
        final gsi = GoogleSignIn.instance;

        // Clear any cached account so the picker always appears
        await gsi.signOut();

        // authenticate() is async — shows the account picker
        final googleUser = await gsi.authenticate();

        // .authentication is a SYNC getter — do NOT await
        final googleAuth = googleUser.authentication;

        if (googleAuth.idToken == null) {
          debugPrint('[Google SignIn] idToken was null');
          return GoogleSignInResult.error;
        }

        // accessToken removed from GoogleSignInAuthentication in v7;
        // idToken alone is sufficient for Firebase Auth
        final oauthCredential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        credential = await auth.signInWithCredential(oauthCredential);
      }

      final uid = credential.user?.uid;
      if (uid == null) return GoogleSignInResult.error;

      // Check Firestore for a complete profile
      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data();

      final isComplete = doc.exists &&
          (data?['onboardingCompleted'] == true) &&
          ((data?['role'] as String?)?.isNotEmpty ?? false);

      return isComplete
          ? GoogleSignInResult.existingUser
          : GoogleSignInResult.newUser;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleSignInResult.cancelled;
      }
      debugPrint(
          '[Google SignIn] ${e.code} — ${e.description ?? 'No description'}');
      return GoogleSignInResult.error;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return GoogleSignInResult.cancelled;
      }
      debugPrint('[FirebaseAuth] ${e.code} — ${e.message}');
      return GoogleSignInResult.error;
    } catch (e) {
      debugPrint('[Unexpected] $e');
      return GoogleSignInResult.error;
    }
  }

  Future<void> completeOnboarding({
    required String uid,
    required String fullName,
    required String role,
    required String yearLevel,
    required String section,
  }) async {
    final user = auth.currentUser;
    await firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': user?.email,
      'role': role,
      'avatarUrl': user?.photoURL ?? '',
      'yearLevel': yearLevel,
      'section': section,
      'onboardingCompleted': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    required String section,
    required String yearLevel,
    String? avatarUrl,
    String? fullName,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
        email: email, password: password);

    await firestore.collection('users').doc(cred.user!.uid).set({
      'fullName': fullName ?? email.split('@')[0],
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'section': section,
      'yearLevel': yearLevel,
      'onboardingCompleted': true,
    });

    return cred;
  }

  Future<UserCredential> signIn(String email, String password) =>
      auth.signInWithEmailAndPassword(email: email, password: password);

  /// Sends a new email verification link to the given [User].
  /// Called from LoginScreen when the user taps "Resend Link".
  Future<void> resendVerificationEmail(User user) =>
      user.sendEmailVerification();

  Future<void> updateUserAvatar(
          {required String uid, required String avatarUrl}) async =>
      firestore.collection('users').doc(uid).update({'avatarUrl': avatarUrl});

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await auth.signOut();
    } catch (e) {
      debugPrint('[SignOut] $e');
    }
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class AuthController {
  final AuthRepository repository;
  AuthController(this.repository);

  Future<GoogleSignInResult> signInWithGoogleAndCheck() =>
      repository.signInWithGoogleAndCheck();

  Future<UserCredential> signIn(String email, String password) =>
      repository.signIn(email, password);

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    required String section,
    required String yearLevel,
    String? avatarUrl,
    String? fullName,
  }) =>
      repository.signUp(
        email: email,
        password: password,
        role: role,
        section: section,
        yearLevel: yearLevel,
        avatarUrl: avatarUrl,
        fullName: fullName,
      );

  /// Delegates to [AuthRepository.resendVerificationEmail].
  Future<void> resendVerificationEmail(User user) =>
      repository.resendVerificationEmail(user);

  Future<void> updateUserAvatar(
          {required String uid, required String avatarUrl}) =>
      repository.updateUserAvatar(uid: uid, avatarUrl: avatarUrl);

  Future<void> signOut() => repository.signOut();

  User? get currentUser => repository.auth.currentUser;
}

// ── Final Providers ───────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final userRoleProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return '';

  final doc = await ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .get();

  return doc.data()?['role'] as String? ?? '';
});
