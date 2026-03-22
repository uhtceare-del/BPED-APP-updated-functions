import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cloudinary_provider.dart'; // Assuming this exports CloudinaryService

final imageUploadProvider = StateNotifierProvider<ImageUploadNotifier, AsyncValue<String?>>((ref) {
  final cloudinary = ref.read(cloudinaryProvider);
  return ImageUploadNotifier(cloudinary);
});

class ImageUploadNotifier extends StateNotifier<AsyncValue<String?>> {
  final CloudinaryService _cloudinary;

  ImageUploadNotifier(this._cloudinary) : super(const AsyncValue.data(null));

  /// Upload from mobile (File)
  Future<String?> upload(File file) async {
    state = const AsyncValue.loading();
    try {
      final url = await _cloudinary.uploadImage(file);
      if (url != null && url.isNotEmpty) {
        state = AsyncValue.data(url);
        return url;
      } else {
        state = AsyncValue.error(
          Exception('Image upload failed - no URL returned'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Upload from web (bytes)
  Future<String?> uploadBytes(
      Uint8List bytes, {
        String filename = 'avatar.jpg',
        String? folder,
      }) async {
    state = const AsyncValue.loading();
    try {
      final url = await _cloudinary.uploadBytes(
        bytes,
        filename: filename,
      );
      if (url != null && url.isNotEmpty) {
        state = AsyncValue.data(url);
        return url;
      } else {
        state = AsyncValue.error(
          Exception('Web image upload failed - no URL returned'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}