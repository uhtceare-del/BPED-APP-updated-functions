import 'package:hive/hive.dart';

part 'offline_material_model.g.dart'; // Required for the generator

@HiveType(typeId: 0)
class OfflineMaterial {
  @HiveField(0)
  final String id; // Use the Firestore document ID

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String originalUrl;

  @HiveField(3)
  final String localFilePath; // Where the PDF/Video is saved on the phone

  OfflineMaterial({
    required this.id,
    required this.title,
    required this.originalUrl,
    required this.localFilePath,
  });
}