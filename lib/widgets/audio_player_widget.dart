import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// A reusable audio player widget that handles both online URLs and local paths.
/// Add just_audio: ^0.9.x to your pubspec.yaml dependencies.
class AudioPlayerWidget extends StatefulWidget {
  final String title;
  final String urlOrPath;
  final bool isOffline;

  const AudioPlayerWidget({
    super.key,
    required this.title,
    required this.urlOrPath,
    this.isOffline = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;
  bool _isLoading = true;
  String? _error;

  static const Color lnuNavy = Color(0xFF002147);

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      if (widget.isOffline) {
        await _player.setFilePath(widget.urlOrPath);
      } else {
        await _player.setUrl(widget.urlOrPath);
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lnuNavy,
      appBar: AppBar(
        backgroundColor: lnuNavy,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load audio:\n$_error',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
        ),
      )
          : _buildPlayer(),
    );
  }

  Widget _buildPlayer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album art placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.headphones, size: 80, color: Colors.white54),
          ),
          const SizedBox(height: 40),

          // Track title
          Text(
            widget.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),

          // Seek bar
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, posSnap) {
              final position = posSnap.data ?? Duration.zero;
              final total = _player.duration ?? Duration.zero;
              final progress = total.inMilliseconds > 0
                  ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                  : 0.0;

              return Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      thumbColor: Colors.white,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white30,
                      overlayColor: Colors.white24,
                      thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (v) {
                        final seek = Duration(
                            milliseconds: (v * total.inMilliseconds).round());
                        _player.seek(seek);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position),
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(_formatDuration(total),
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Rewind 10s
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                onPressed: () {
                  final pos = _player.position;
                  _player.seek(Duration(
                      seconds: (pos.inSeconds - 10).clamp(0, double.infinity).toInt()));
                },
              ),

              // Play / Pause
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snap) {
                  final state = snap.data;
                  final playing = state?.playing ?? false;
                  final processingState = state?.processingState;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(32)),
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    );
                  }

                  return GestureDetector(
                    onTap: playing ? _player.pause : _player.play,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32)),
                      child: Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        color: lnuNavy,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),

              // Forward 10s
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                onPressed: () {
                  final pos = _player.position;
                  final dur = _player.duration?.inSeconds ?? 0;
                  _player.seek(Duration(
                      seconds: (pos.inSeconds + 10).clamp(0, dur)));
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Speed selector
          StreamBuilder<double>(
            stream: _player.speedStream,
            builder: (context, snap) {
              final speed = snap.data ?? 1.0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Speed: ',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  DropdownButton<double>(
                    value: speed,
                    dropdownColor: lnuNavy,
                    style: const TextStyle(color: Colors.white),
                    underline: const SizedBox(),
                    items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                        .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s}x',
                            style: const TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (s) {
                      if (s != null) _player.setSpeed(s);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}