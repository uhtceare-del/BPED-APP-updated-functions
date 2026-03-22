import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_material_model.dart';
import '../providers/offline_provider.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/audio_player_widget.dart';

class OfflineDownloadsScreen extends ConsumerWidget {
  const OfflineDownloadsScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = Hive.box('downloadsBox');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offline Files',
            style:
            TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: lnuNavy),
        elevation: 0.5,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box currentBox, _) {
          if (currentBox.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_for_offline_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No files downloaded yet.',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  const Text(
                    'Go to Reviewers or Lessons to save materials.',
                    style: TextStyle(color: Colors.black38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final materials =
          currentBox.values.cast<OfflineMaterial>().toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              final type = _mediaType(material.localFilePath);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: _buildIcon(type),
                  title: Text(material.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_typeLabel(type),
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 22),
                    tooltip: 'Remove from device',
                    onPressed: () async {
                      await ref
                          .read(offlineStorageProvider)
                          .deleteFile(material.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                              Text('${material.title} removed.')),
                        );
                      }
                    },
                  ),
                  onTap: () => _openFile(context, material, type),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _mediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'avi'].contains(ext)) return 'video';
    if (['mp3', 'm4a', 'wav', 'aac'].contains(ext)) return 'audio';
    return 'pdf';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'video':
        return 'Video • Available Offline';
      case 'audio':
        return 'Audio • Available Offline';
      default:
        return 'PDF • Available Offline';
    }
  }

  Widget _buildIcon(String type) {
    switch (type) {
      case 'video':
        return CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.play_circle_fill,
              color: Colors.blue, size: 22),
        );
      case 'audio':
        return CircleAvatar(
          backgroundColor: Colors.purple.shade50,
          child: const Icon(Icons.headphones,
              color: Colors.purple, size: 22),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: const Icon(Icons.picture_as_pdf,
              color: Colors.red, size: 22),
        );
    }
  }

  void _openFile(
      BuildContext context, OfflineMaterial material, String type) {
    switch (type) {
      case 'video':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerWidget(
              title: material.title,
              urlOrPath: material.localFilePath,
              isOffline: true,
            ),
          ),
        );
        break;
      case 'audio':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerWidget(
              title: material.title,
              urlOrPath: material.localFilePath,
              isOffline: true,
            ),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerWidget(
              title: material.title,
              urlOrPath: material.localFilePath,
              isOffline: true,
            ),
          ),
        );
    }
  }
}