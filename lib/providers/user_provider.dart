import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// All students — used in ClassScreen enroll dialog
final studentsProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(firestoreProvider)
      .collection('users')
      .where('role', isEqualTo: 'student')
      .snapshots()
      .map((snap) => snap.docs
      .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
      .toList());
});

// Current user's avatar URL — used in HomeScreen
final avatarUrlProvider = StreamProvider<String?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(authState.uid)
      .snapshots()
      .map((snap) => snap.data()?['avatarUrl'] as String?);
});