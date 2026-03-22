import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore firestore;

  UserRepository(this.firestore);

  // Stream all students
  Stream<List<AppUser>> getAllStudents() {
    return firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Get user by ID
  AppUser getUserById(String uid) {
    final doc = firestore.collection('users').doc(uid);
    // For simplicity, return dummy data if not yet fetched. In practice use Future/Stream.
    return AppUser(uid: uid, email: '', role: '', avatarUrl: '', createdAt: DateTime.now());
  }

  // Create or update user
  Future<void> createUser(AppUser user) async {
    await firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }
}