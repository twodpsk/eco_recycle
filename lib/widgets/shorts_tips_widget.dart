import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ShortsTipsWidget extends StatefulWidget {
  final String videoId;
  final String title;

  const ShortsTipsWidget({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<ShortsTipsWidget> createState() => _ShortsTipsWidgetState();
}

class _ShortsTipsWidgetState extends State<ShortsTipsWidget> {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initializePlayer() {
    setState(() {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
      _isPlayerReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 영상 영역 ---
          AspectRatio(
            aspectRatio: 0.6,
            child: _isPlayerReady && _controller != null
                ? YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.green,
              onReady: () {},
            )
                : GestureDetector(
              onTap: _initializePlayer,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://img.youtube.com/vi/${widget.videoId}/0.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.grey[300]);
                    },
                  ),
                  Container(color: Colors.black.withOpacity(0.3)),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 60.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 제목 영역 ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
