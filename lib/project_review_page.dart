import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/projects_page.dart';
import 'package:video_player/video_player.dart';

class ProjectReviewPage extends StatefulWidget {
  const ProjectReviewPage({
    Key? key,
    required this.projectName,
    required this.authorName,
    required this.publishedDate,
    required this.description,
    required this.videoUrl,
    required this.activity,
    this.reactionCounts = 0,
  }) : super(key: key);
  final EnrichedActivity activity;
  final int reactionCounts;
  final String projectName;
  final String authorName;
  final DateTime publishedDate;
  final String description;
  final String videoUrl;

  @override
  State<ProjectReviewPage> createState() => _ProjectReviewPageState();
}

class _ProjectReviewPageState extends State<ProjectReviewPage> {
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
    _videoPlayerController1 = VideoPlayerController.network(widget.videoUrl);

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
          widget.projectName,
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
            child: Text(widget.projectName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text(widget.authorName,
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(' uploaded ${formatPublishedDate(widget.publishedDate)}',
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold))
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.description,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
            child: Text('${widget.reactionCounts} Comments'),
          ),
          Expanded(
            child: CommentListView(
              key: Key('${widget.activity.id}_comments'),
              activity: widget.activity,
              chewieController: _chewieController,
              lookupValue: widget.activity.id!,
            ),
          ),
          // Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CommentSectionCard(activity: widget.activity),
          ),
        ],
      ),
    );
  }
}

class CommentSectionCard extends StatelessWidget {
  const CommentSectionCard({Key? key, required this.activity})
      : super(key: key);
  final EnrichedActivity activity;

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
                child: FrameAvatar(
                    url: FeedProvider.of(context)
                            .bloc
                            .currentUser!
                            .data?['profile_image'] as String? ??
                        'https://i.pravatar.cc/300'),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: textController,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Leave your comment here',
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.timer),
                      const SizedBox(
                        width: 12,
                      ),
                      //TODO: update this value continuously (in a performant way) from
                      // _chewieController!.videoPlayerController.value.position
                      //save it in a field so it's usable by as timestamp param for
                      //onAddReaction
                      Text(convertDuration(const Duration(seconds: 2))),
                    ],
                  ),
                ),
                TextButton(
                  child: const Text('Send'),
                  onPressed: () {
                    FeedProvider.of(context).bloc.onAddReaction(
                      kind: 'comment',
                      activity: activity,
                      feedGroup: 'video_timeline',
                      data: {
                        'timestamp': 12, //TODO: unhardcode this
                        'text': textController.text, //_
                      },
                    );
                    textController.clear();
                  },
                )
              ],
            ),
          ) //convertDuration(position)
        ],
      ),
    );
  }
}

class CommentListView extends StatelessWidget {
  const CommentListView(
      {Key? key,
      ChewieController? chewieController,
      required this.activity,
      required this.lookupValue,
      this.lookupAttr = LookupAttribute.activityId})
      : _chewieController = chewieController,
        super(key: key);
  final EnrichedActivity activity;
  final ChewieController? _chewieController;
  final LookupAttribute lookupAttr;
  final String lookupValue;

  @override
  Widget build(BuildContext context) {
    return ReactionListCore(
      lookupValue: lookupValue,
      lookupAttr: lookupAttr,
      kind: 'comment',
      flags: EnrichmentFlags()
          .withOwnChildren()
          .withOwnReactions()
          .withReactionCounts(),
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      emptyBuilder: (context) => const Offstage(),
      errorBuilder: (context, error) => Center(
        child: Text(error.toString()),
      ),
      reactionsBuilder: (BuildContext context, List<Reaction> reactions) {
        return ListView.separated(
          scrollDirection: Axis.vertical,
          separatorBuilder: (context, index) => const Divider(),
          shrinkWrap: true,
          reverse: true,
          itemCount: reactions.length,
          itemBuilder: (context, index) => FrameComment(
              key: ValueKey('reaction-${reactions[index].id}'),
              lookupValue: lookupValue,
              lookupAttr: lookupAttr,
              reaction: reactions[index],
              activity: activity,
              username: reactions[index].user!.data!['full_name'] as String,
              avatarUrl:
                  reactions[index].user!.data!['profile_image'] as String? ??
                      'https://i.pravatar.cc/300',
              timestamp: reactions[index].data!['timestamp'] as int?,
              text: reactions[index].data!['text'] as String,
              date: reactions[index].createdAt!,
              numberOfComments: reactions[index].childrenCounts?['comment'],
              isLikedByUser:
                  (reactions[index].ownChildren?['like']?.length ?? 0) > 0,
              numberOfLikes: reactions[index].childrenCounts?['like'],
              onSeekTo: _chewieController != null
                  ? (int timestamp) {
                      _chewieController?.seekTo(Duration(seconds: timestamp));
                    }
                  : null),
        );
      },
    );
  }
}

class FrameComment extends StatefulWidget {
  const FrameComment({
    Key? key,
    required this.timestamp,
    required this.text,
    required this.date,
    required this.username,
    required this.onSeekTo,
    required this.avatarUrl,
    required this.reaction,
    required this.activity,
    required this.lookupValue,
    required this.lookupAttr,
    required this.numberOfLikes,
    required this.isLikedByUser,
    required this.numberOfComments,
  }) : super(key: key);
  final LookupAttribute lookupAttr;
  final Reaction reaction;
  final EnrichedActivity activity;
  final int? timestamp;
  final DateTime date;
  final String text;
  final String username;
  final String avatarUrl;
  final int? numberOfLikes;
  final int? numberOfComments;
  final String lookupValue;
  final bool isLikedByUser;
  final void Function(int timestamp)? onSeekTo;

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
              FrameAvatar(url: widget.avatarUrl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  widget.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  formatPublishedDate(widget.date),
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
                        widget.timestamp != null
                            ? convertDuration(
                                Duration(seconds: widget.timestamp!))
                            : '',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    onTap: () {
                      widget.onSeekTo!(widget.timestamp!);
                    },
                  )
                : const SizedBox(width: 45),
            Text(widget.text),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: widget.isLikedByUser
                  ? const Icon(Icons.thumb_up, size: 14)
                  : const Icon(Icons.thumb_up_outlined, size: 14),
              onPressed: () {
                if (widget.isLikedByUser) {
                  FeedProvider.of(context).bloc.onRemoveChildReaction(
                        kind: 'like',
                        lookupValue: widget.lookupValue,
                        lookupAttr: widget.lookupAttr,
                        childReaction: widget.reaction.ownChildren!['like']![0],
                        activity: widget.activity,
                        parentReaction: widget.reaction,
                      );
                } else {
                  FeedProvider.of(context).bloc.onAddChildReaction(
                        kind: 'like',
                        lookupValue: widget.lookupValue,
                        lookupAttr: widget.lookupAttr,
                        reaction: widget.reaction,
                        activity: widget.activity,
                      );
                }
              },
            ),
            if (widget.numberOfLikes != null && widget.numberOfLikes! > 0)
              Text(
                widget.numberOfLikes!.toString(),
                style: const TextStyle(fontSize: 14),
              ),
            TextButton(
              child: const Text(
                'Reply',
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
                  await FeedProvider.of(context).bloc.onAddChildReaction(
                    kind: 'comment',
                    reaction: widget.reaction,
                    activity: widget.activity,
                    lookupAttr: widget.lookupAttr,
                    lookupValue: widget.lookupValue,
                    data: {
                      'text': replyController.text,
                    },
                  );
                  replyController.clear();
                },
              )
          ],
        ),
        if (widget.numberOfComments != null && widget.numberOfComments! > 0)
          TextButton(
            child: Text(
              '${displayReplies ? 'Hide' : 'View'} ${widget.numberOfComments!} replies',
              style: const TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              setState(() {
                displayReplies = !displayReplies;
              });
            },
          ),
        if (displayReplies)
          Row(
            // mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(
                width: 40,
              ),
              Expanded(
                child: CommentListView(
                  key: Key('${widget.reaction.id}_comments'),
                  activity: widget.activity,
                  lookupAttr: LookupAttribute.reactionId,
                  lookupValue: widget.reaction.id!,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class ReplyTextField extends StatelessWidget {
  const ReplyTextField({Key? key, required this.replyController})
      : super(key: key);
  final TextEditingController replyController;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: TextField(
          controller: replyController,
        ),
      );
}

class FrameAvatar extends StatelessWidget {
  const FrameAvatar({
    Key? key,
    required this.url,
  }) : super(key: key);
  final String url;

  @override
  Widget build(BuildContext context) => CircleAvatar(
      backgroundImage: NetworkImage(
        url,
      ),
      radius: 14);
}

String convertDuration(Duration timestamp) {
  final minutes = timestamp.inMinutes % 60;
  final seconds = timestamp.inSeconds % 60;
  return '$minutes:$seconds';
}
