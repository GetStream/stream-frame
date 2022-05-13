import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/avatar.dart';
import 'package:stream_frame/builders/reactions.dart';
import 'package:stream_frame/models.dart';
import 'package:stream_frame/utils.dart';
import 'package:stream_frame/video.dart';
import 'package:video_player/video_player.dart';

/// The bottom card in the [ReviewProjectPage] to leave a commenr at a certain
/// timestamp
class CommentSectionCard extends StatelessWidget {
  const CommentSectionCard({
    Key? key,
    required this.videoPlayerController,
    required this.userProfileImage,
    required this.onComment,
  }) : super(key: key);
  final VideoPlayerController videoPlayerController;
  final String userProfileImage;
  final Future<void> Function(int timestamp, String text) onComment;

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();
    return Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FrameAvatar(url: userProfileImage),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: textController,
                      onTap: () {
                        videoPlayerController.pause();
                      },
                      decoration: const InputDecoration.collapsed(
                        hintText: "Leave your comment here",
                      )),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VideoPositionIndicator(videoPlayerController),
                TextButton(
                  child: const Text("Send"),
                  onPressed: () async {
                    final timestamp = await videoPlayerController.position;
                    await onComment(timestamp != null ? timestamp.inSeconds : 0,
                        textController.text);

                    textController.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// A ListView of [FrameComment]s
class CommentListView extends StatelessWidget {
  const CommentListView({
    Key? key,
    required this.lookupValue,
    required this.reactions,
    required ChewieController? chewieController,
  })  : _chewieController = chewieController,
        super(key: key);

  final String lookupValue;
  final List<Reaction> reactions;
  final ChewieController? _chewieController;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        scrollDirection: Axis.vertical,
        separatorBuilder: (context, index) => const Divider(),
        shrinkWrap: true,
        reverse: true,
        itemCount: reactions.length,
        itemBuilder: (context, index) => FrameComment(
              commentModel:
                  FrameCommentModel.fromReaction(reactions[index], lookupValue),
              buildReplies: (context) {
                return Row(
                  children: [
                    const SizedBox(
                      width: 40,
                    ),
                    Expanded(
                      child: CommentListViewBuilder(
                        lookupAttr: LookupAttribute.reactionId,
                        lookupValue: reactions[index].id!,
                      ),
                    ),
                  ],
                );
              },
              onToggleLikeReaction: (isLikedByUser) async {
                if (isLikedByUser) {
                  FeedProvider.of(context).bloc.onRemoveChildReaction(
                        kind: 'like',
                        lookupValue: lookupValue,
                        childReaction:
                            reactions[index].ownChildren!['like']![0],
                        parentReaction: reactions[index],
                      );
                } else {
                  FeedProvider.of(context).bloc.onAddChildReaction(
                        kind: 'like',
                        lookupValue: lookupValue,
                        reaction: reactions[index],
                      );
                }
              },
              onSeekTo: _chewieController != null
                  ? (int timestamp) async {
                      await _chewieController
                          ?.seekTo(Duration(seconds: timestamp));
                    }
                  : null,
              onReply: (reply) async {
                await FeedProvider.of(context).bloc.onAddChildReaction(
                  kind: "comment",
                  reaction: reactions[index],
                  lookupValue: lookupValue,
                  data: {"text": reply},
                );
              },
            ));
  }
}

/// The widget that handle youtube style comments, with a seekTo callback to seek 
/// the video to the timestamp of the comment
class FrameComment extends StatefulWidget {
  const FrameComment({
    Key? key,
    required this.onSeekTo,
    required this.onReply,
    required this.onToggleLikeReaction,
    required this.buildReplies,
    required this.commentModel,
  }) : super(key: key);
  final FrameCommentModel commentModel;

  /// The callback to seek the video to the timestamp of the comment
  final Future<void> Function(int timestamp)? onSeekTo;

  /// The callback to reply to the comment
  final Future<void> Function(String reply) onReply;

  /// The callback to toggle the like reaction
  final Future<void> Function(bool isLikedByUser) onToggleLikeReaction;

  /// Build the replies to the comment
  final Widget Function(BuildContext) buildReplies;

  @override
  State<FrameComment> createState() => _FrameCommentState();
}

class _FrameCommentState extends State<FrameComment> {
  bool showTextField = false;
  bool displayReplies = false;
  final replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FrameAvatar(url: widget.commentModel.avatarUrl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  widget.commentModel.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  formatPublishedDate(widget.commentModel.date),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            widget.onSeekTo != null
                ? GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 12.0),
                      child: Text(
                        widget.commentModel.timestamp != null
                            ? convertDuration(Duration(
                                seconds: widget.commentModel.timestamp!))
                            : "",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    onTap: () {
                      widget.onSeekTo!(widget.commentModel.timestamp!);
                    },
                  )
                : const SizedBox(width: 45),
            Text(widget.commentModel.text),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: widget.commentModel.isLikedByUser
                  ? const Icon(Icons.thumb_up, size: 14)
                  : const Icon(Icons.thumb_up_outlined, size: 14),
              onPressed: () async {
                await widget
                    .onToggleLikeReaction(widget.commentModel.isLikedByUser);
              },
            ),
            if (widget.commentModel.numberOfLikes != null &&
                widget.commentModel.numberOfLikes! > 0)
              Text(
                widget.commentModel.numberOfLikes!.toString(),
                style: const TextStyle(fontSize: 14),
              ),
            TextButton(
              child: const Text(
                "Reply",
                style: TextStyle(fontSize: 14),
              ),
              onPressed: () {
                setState(() {
                  showTextField = !showTextField;
                });
              },
            ),
            if (showTextField)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ReplyTextField(replyController: replyController),
              ),
            if (showTextField)
              IconButton(
                icon: const Icon(
                  Icons.send,
                  size: 12,
                ),
                onPressed: () async {
                  await widget.onReply(replyController.text);
                  replyController.clear();
                },
              )
          ],
        ),
        if (widget.commentModel.numberOfComments != null &&
            widget.commentModel.numberOfComments! > 0)
          TextButton(
            child: Text(
              "${displayReplies ? 'Hide' : 'View'} ${widget.commentModel.numberOfComments!} replies",
              style: const TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              setState(() {
                displayReplies = !displayReplies;
              });
            },
          ),
        if (displayReplies) widget.buildReplies(context),
      ],
    );
  }
}

/// A sized text field to reply to a comment
class ReplyTextField extends StatelessWidget {
  const ReplyTextField({Key? key, required this.replyController})
      : super(key: key);
  final TextEditingController replyController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 150,
        child: TextField(
          controller: replyController,
        ));
  }
}
