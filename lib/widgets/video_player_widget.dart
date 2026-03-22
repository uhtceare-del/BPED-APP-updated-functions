import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String title;
  final String urlOrPath;
  final bool isOffline;

  const VideoPlayerWidget({
    super.key,
    required this.title,
    required this.urlOrPath,
    this.isOffline = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // 1. Choose the data source
    if (widget.isOffline) {
      _videoPlayerController = VideoPlayerController.file(File(widget.urlOrPath));
    } else {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.urlOrPath));
    }

    // 2. Initialize the player
    await _videoPlayerController.initialize();

    // 3. Wrap it in Chewie for the UI controls
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).primaryColor,
        handleColor: Theme.of(context).primaryColor,
        backgroundColor: Colors.grey.shade300,
        bufferedColor: Colors.grey.shade400,
      ),
    );

    // Rebuild the UI now that the video is ready
    setState(() {});
  }

  @override
  void dispose() {
    // ALWAYS dispose controllers to prevent memory leaks
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _chewieController != null &&
            _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}