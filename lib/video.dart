
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/utils.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

/// A widget to display the current video position
class VideoPositionIndicator extends StatefulWidget {
  const VideoPositionIndicator(
    this.controller, {
    Key? key,
  }) : super(key: key);

  final VideoPlayerController controller;

  @override
  _VideoPositionIndicatorState createState() => _VideoPositionIndicatorState();
}

class _VideoPositionIndicatorState extends State<VideoPositionIndicator> {
  _VideoPositionIndicatorState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  late VoidCallback listener;

  VideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.value.isInitialized) {
      final Duration position = controller.value.position;

      return Row(
        children: [
          const Icon(Icons.timer),
          const SizedBox(
            width: 12,
          ),
          Text(convertDuration(position)),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.timer),
        const SizedBox(
          width: 12,
        ),
        Text(convertDuration(const Duration(seconds: 0))),
      ],
    );
  }
}

/// A card used in the [NewProjectDialog] widget to display the video preview

class VideoPreviewCard extends StatefulWidget {
  const VideoPreviewCard(this.file, {Key? key}) : super(key: key);
  final AttachmentFile file;

  @override
  State<VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<VideoPreviewCard> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  @override
  void initState() {
    super.initState();

    initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController =
        VideoPlayerController.file(File(widget.file.path!));

    await _videoPlayerController.initialize();
    _createChewieController();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 5,
      margin: const EdgeInsets.all(5),
      child: _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(
              controller: _chewieController!,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Loading'),
              ],
            ),
    );
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
    );
  }
}
