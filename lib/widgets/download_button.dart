import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/offline_provider.dart';

class DownloadButton extends ConsumerStatefulWidget {
  final String materialId;
  final String title;
  final String url;
  final String fileExtension; // e.g., '.pdf' or '.mp4'

  const DownloadButton({
    super.key,
    required this.materialId,
    required this.title,
    required this.url,
    required this.fileExtension,
  });

  @override
  ConsumerState<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<DownloadButton> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the Hive service
    final offlineService = ref.watch(offlineStorageProvider);

    // Check if it's already in the local Hive box
    final isDownloaded = offlineService.isDownloaded(widget.materialId);

    if (isDownloaded) {
      return IconButton(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        tooltip: 'Available Offline',
        onPressed: () {
          // Future step: We will add logic here to actually open the local file!
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File is already available offline.')),
          );
        },
      );
    }

    if (_isDownloading) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      tooltip: 'Download for offline use',
      onPressed: () async {
        setState(() => _isDownloading = true);
        try {
          await offlineService.downloadFile(
            id: widget.materialId,
            title: widget.title,
            url: widget.url,
            fileExtension: widget.fileExtension,
          );

          // Rebuild to show the green checkmark
          if (mounted) setState(() {});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download complete!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Download failed: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isDownloading = false);
        }
      },
    );
  }
}