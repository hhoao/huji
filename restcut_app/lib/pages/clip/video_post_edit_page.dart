import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPostEditPage extends StatefulWidget {
  final String videoUrl;
  const VideoPostEditPage({super.key, required this.videoUrl});

  @override
  State<VideoPostEditPage> createState() => _VideoPostEditPageState();
}

class _VideoPostEditPageState extends State<VideoPostEditPage> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) => setState(() {}));
    _controller.addListener(() {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildEditButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(
                icon,
                size: 32,
                color: highlight ? Colors.pink : Colors.black87,
              ),
              if (highlight)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '限免',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频编辑'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 视频播放器
            AspectRatio(
              aspectRatio: _controller.value.isInitialized
                  ? _controller.value.aspectRatio
                  : 16 / 9,
              child: _controller.value.isInitialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),
                        if (!_isPlaying)
                          GestureDetector(
                            onTap: () => _controller.play(),
                            child: Container(
                              color: Colors.black26,
                              child: const Icon(
                                Icons.play_circle_fill,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '1080P',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 80,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {},
                            child: const Text(
                              '导出',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            // 时间轴
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _controller.value.isInitialized
                        ? _formatDuration(_controller.value.position)
                        : '00:00',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  Expanded(
                    child: Slider(
                      value: _controller.value.isInitialized
                          ? _controller.value.position.inSeconds.toDouble()
                          : 0,
                      min: 0,
                      max: _controller.value.isInitialized
                          ? _controller.value.duration.inSeconds.toDouble()
                          : 1,
                      onChanged: (v) {
                        if (_controller.value.isInitialized) {
                          _controller.seekTo(Duration(seconds: v.toInt()));
                        }
                      },
                      activeColor: Colors.pink,
                      inactiveColor: Colors.white24,
                    ),
                  ),
                  Text(
                    _controller.value.isInitialized
                        ? _formatDuration(_controller.value.duration)
                        : '00:00',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            // 编辑功能区
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEditButton(Icons.content_cut, '剪辑'),
                  _buildEditButton(Icons.music_note, '音频'),
                  _buildEditButton(Icons.text_fields, '文字'),
                  _buildEditButton(Icons.movie_filter, 'AI剪辑', highlight: true),
                  _buildEditButton(Icons.emoji_emotions, '贴纸'),
                  _buildEditButton(Icons.picture_in_picture, '画中画'),
                ],
              ),
            ),
            // 占位区（可扩展为功能面板）
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: const Center(
                  child: Text(
                    '可在这里扩展更多编辑功能',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
