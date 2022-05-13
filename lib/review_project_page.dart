import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/builders/reactions.dart';
import 'package:stream_frame/comments.dart';
import 'package:stream_frame/models.dart';
import 'package:stream_frame/theme.dart';
import 'package:stream_frame/utils.dart';
import 'package:video_player/video_player.dart';

/// A page that displays a video and its review comments.
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
        VideoPlayerController.network(widget.reviewProjectModel.videoUrl);

    await _videoPlayerController.initialize();
    _createChewieController();
    setState(() {});
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
                      _chewieController!
                          .videoPlayerController.value.isInitialized
                  ?
                  //The video player
                  Chewie(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
              child: Text(widget.reviewProjectModel.projectName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(widget.reviewProjectModel.authorName,
                      style: const TextStyle(
                          color: StreamAppColors.darkGrey,
                          fontWeight: FontWeight.bold)),
                  Text(
                      " uploaded ${formatPublishedDate(widget.reviewProjectModel.publishedDate)}",
                      style: const TextStyle(
                          color: StreamAppColors.darkGrey,
                          fontWeight: FontWeight.bold))
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                widget.reviewProjectModel.description,
                style: const TextStyle(color: StreamAppColors.darkGrey),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
              child:
                  Text("${widget.reviewProjectModel.reactionCounts} Comments"),
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
                videoPlayerController: _videoPlayerController,
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
        ));
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
    );
  }
}
