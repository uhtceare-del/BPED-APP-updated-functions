import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as p;

final cloudinaryProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

class CloudinaryService {
  final String cloudName = 'duviaos3y';
  final String uploadPreset = 'daren_unsigned';

  /// Upload any file by local path — auto-detects resource type.
  Future<String?> uploadFile(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    // PDFs must use 'raw' — 'auto' rejects them on many unsigned presets
    final resType = ext == '.pdf' ? 'raw' : _typeFromExt(ext);
    return _upload(
      filePath: filePath,
      bytes: null,
      filename: p.basename(filePath),
      resourceType: resType,
    );
  }

  /// Explicit PDF upload — always uses 'raw' resource type.
  /// Call this directly from the reviewer upload flow.
  Future<String?> uploadPdf(String filePath) async {
    return _upload(
      filePath: filePath,
      bytes: null,
      filename: p.basename(filePath),
      resourceType: 'raw',
    );
  }

  /// Upload a File object (profile pictures / avatars).
  Future<String?> uploadImage(File file) async {
    return _upload(
      filePath: file.path,
      bytes: null,
      filename: p.basename(file.path),
      resourceType: 'image',
    );
  }

  /// Upload raw bytes — used on Flutter Web where file paths are unavailable.
  /// Also correctly handles PDFs via 'raw' resource type.
  Future<String?> uploadBytes(Uint8List bytes,
      {String filename = 'file.pdf'}) async {
    final ext = p.extension(filename).toLowerCase();
    final resType = ext == '.pdf' ? 'raw' : _typeFromExt(ext);
    return _upload(
      filePath: null,
      bytes: bytes,
      filename: filename,
      resourceType: resType,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _typeFromExt(String ext) {
    if (['.mp4', '.mov', '.avi'].contains(ext)) return 'video';
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) return 'image';
    return 'raw';
  }

  Future<String?> _upload({
    String? filePath,
    Uint8List? bytes,
    required String filename,
    required String resourceType,
  }) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset;

      if (filePath != null) {
        request.files
            .add(await http.MultipartFile.fromPath('file', filePath));
      } else if (bytes != null) {
        request.files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename));
      } else {
        throw ArgumentError('Either filePath or bytes must be provided.');
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      } else {
        // Print full Cloudinary error so it shows in flutter run logs
        print('[Cloudinary] Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[Cloudinary] Exception: $e');
      return null;
    }
  }
}