

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/builders/reactions.dart';
import 'package:stream_frame/comments.dart';
import 'package:stream_frame/models.dart';
import 'package:stream_frame/utils.dart';
import 'package:video_player/video_player.dart';

class ReviewProjectPage extends StatefulWidget {
  const ReviewProjectPage({
    Key? key,
    required this.reviewProjectModel,
  }) : super(key: key);
  final ReviewProjectModel reviewProjectModel;

  @override
  State<ReviewProjectPage> createState() => _ReviewProjectPageState();
}

class _ReviewProjectPageState extends State<ReviewProjectPage> {
  late VideoPlayerController _videoPlayerController1;
  ChewieController? _chewieController;
  @override
  void initState() {
    super.initState();

    initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController1.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController1 =
        VideoPlayerController.network(widget.reviewProjectModel.videoUrl);

    await _videoPlayerController1.initialize();
    _createChewieController();
    setState(() {});
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1,
      autoPlay: true,
      looping: true,
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: toggleVideo,
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
          ),
        ];
      },
      subtitleBuilder: (context, dynamic subtitle) => Container(
        padding: const EdgeInsets.all(10.0),
        child: subtitle is InlineSpan
            ? RichText(
                text: subtitle,
              )
            : Text(
                subtitle.toString(),
                style: const TextStyle(color: Colors.black),
              ),
      ),
      hideControlsTimer: const Duration(seconds: 1),
    );
  }

  int currPlayIndex = 0;

  Future<void> toggleVideo() async {
    await _videoPlayerController1.pause();
    currPlayIndex = currPlayIndex == 0 ? 1 : 0;
    await initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reviewProjectModel.projectName,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.maxFinite,
            height: 100,
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
            child: Text(widget.reviewProjectModel.projectName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text(widget.reviewProjectModel.authorName,
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(
                    " uploaded ${formatPublishedDate(widget.reviewProjectModel.publishedDate)}",
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold))
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.reviewProjectModel.description,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
            child: Text("${widget.reviewProjectModel.reactionCounts} Comments"),
          ),
          Expanded(
            child: CommentListViewBuilder(
              key: Key("${widget.reviewProjectModel.activity.id}_comments"),
              chewieController: _chewieController,
              lookupValue: widget.reviewProjectModel.activity.id!,
            ),
          ),
          // Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CommentSectionCard(
              userProfileImage: FeedProvider.of(context)
                      .bloc
                      .currentUser!
                      .data?["profile_image"] as String? ??
                  "https://i.pravatar.cc/300",
              videoPlayerController: _videoPlayerController1,
              onComment: (timestamp, text) async {
                await FeedProvider.of(context).bloc.onAddReaction(
                  kind: "comment",
                  activity: widget.reviewProjectModel.activity,
                  feedGroup: 'video_timeline',
                  data: {
                    "timestamp": timestamp,
                    "text": text,
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}