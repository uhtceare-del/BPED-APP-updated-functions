import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/offline_material_model.dart';

final offlineStorageProvider = Provider<OfflineStorageService>((ref) {
  return OfflineStorageService();
});

class OfflineStorageService {
  final _box = Hive.box('downloadsBox');
  final Dio _dio = Dio();

  // Get all downloaded materials
  List<OfflineMaterial> getDownloadedMaterials() {
    return _box.values.cast<OfflineMaterial>().toList();
  }

  // Check if a specific file is already downloaded
  bool isDownloaded(String id) {
    return _box.containsKey(id);
  }

  // Download a file and save it to Hive
  Future<void> downloadFile({
    required String id,
    required String title,
    required String url,
    required String fileExtension, // e.g., '.pdf' or '.mp4'
  }) async {
    try {
      // 1. Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      final savePath = '${directory.path}/$id$fileExtension';

      // 2. Download the file
      await _dio.download(url, savePath);

      // 3. Save the record to Hive
      final offlineMaterial = OfflineMaterial(
        id: id,
        title: title,
        originalUrl: url,
        localFilePath: savePath,
      );

      await _box.put(id, offlineMaterial);
      print('Download complete and saved to Hive!');

    } catch (e) {
      print('Download failed: $e');
      throw Exception('Failed to download file');
    }
  }

  // Delete a downloaded file
  Future<void> deleteFile(String id) async {
    final material = _box.get(id) as OfflineMaterial?;
    if (material != null) {
      final file = File(material.localFilePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _box.delete(id);
    }
  }
}