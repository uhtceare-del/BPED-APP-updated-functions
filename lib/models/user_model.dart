import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? fullName; // Added to fix Dashboard getter error
  final String role;
  final String avatarUrl;
  final DateTime createdAt;
  final String? section;
  final String? yearLevel;
  final bool onboardingCompleted; // Added for better routing logic

  AppUser({
    required this.uid,
    required this.email,
    this.fullName, // Now part of the constructor
    required this.role,
    required this.avatarUrl,
    required this.createdAt,
    this.section,
    this.yearLevel,
    this.onboardingCompleted = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'onboardingCompleted': onboardingCompleted,
      if (section != null) 'section': section,
      if (yearLevel != null) 'yearLevel': yearLevel,
    };
  }

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'], // Safely maps the new field
      role: data['role'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      section: data['section'],
      // Safely handles both old integer data and new string data
      yearLevel: data['yearLevel']?.toString(),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
    );
  }
}