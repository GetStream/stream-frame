import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:timeago/timeago.dart' as timeago;

// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';

class StreamFrame extends StatefulWidget {
  const StreamFrame(
      {Key? key, this.title = 'Chewie Demo', required this.client})
      : super(key: key);
  final StreamFeedClient client;
  final String title;

  @override
  State<StatefulWidget> createState() {
    return _StreamFrameState();
  }
}

class _StreamFrameState extends State<StreamFrame> {
  TargetPlatform? _platform;

  @override
  Widget build(BuildContext context) {
    var materialApp = MaterialApp(
        builder: (context, child) => FeedProvider(
              bloc: FeedBloc(
                client: widget.client,
              ),
              child: child!,
            ),
        title: widget.title,
        theme: AppTheme.light.copyWith(
          platform: _platform ?? Theme.of(context).platform,
        ),
        home: const Projects());
    return materialApp;
  }
}

class Projects extends StatelessWidget {
  const Projects({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).restorablePush(_dialogBuilder);
            },
            child: const Icon(
              Icons.add,
            )),
        appBar: AppBar(
          title: const Text(
            "Stream Frame",
          ),
        ),
        body: const ProjectPreviewBuilder());
  }

  static Route<Object?> _dialogBuilder(
      BuildContext context, Object? arguments) {
    return DialogRoute<void>(
      context: context,
      builder: (BuildContext context) => const NewProjectDialog(),
    );
  }
}

class ProjectPreviewBuilder extends StatelessWidget {
  const ProjectPreviewBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatFeedCore(
      feedGroup: 'video_timeline',
      userId: FeedProvider.of(context).bloc.currentUser!.id,
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      emptyBuilder: (context) =>
          const Center(child: Text('No video to review')),
      errorBuilder: (context, error) => Center(
        child: Text(error.toString()),
      ),
      limit: 10,
      flags: EnrichmentFlags().withReactionCounts().withOwnReactions(),
      feedBuilder: (context, activities) {
        return GridView.builder(
          itemCount: activities.length,
          itemBuilder: (context, index) => ProjectPreview(
            reviewModel: ReviewProjectModel.fromActivity(activities[index]),
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
        );
      },
    );
  }
}

class NewProjectDialog extends StatelessWidget {
  const NewProjectDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectNameController = TextEditingController();
    final projectDescController = TextEditingController();
    final uploadController = FeedProvider.of(context).bloc.uploadController;
    return SimpleDialog(title: const Text('New project'), children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: projectNameController,
            decoration: const InputDecoration.collapsed(
              hintText: "Enter Project Name",
            )),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: projectDescController,
            decoration: const InputDecoration.collapsed(
              hintText: "Enter Project Description",
            )),
      ),
      const UploadFileButton(),
      SizedBox(
        width: double.maxFinite,
        child: UploadListCore(
          uploadController: uploadController,
          loadingBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          uploadsErrorBuilder: (error) => Center(child: Text(error.toString())),
          uploadsBuilder: (context, uploads) {
            return uploads.isNotEmpty
                ? SizedBox(
                    width: double.maxFinite,
                    height: 200,
                    child: FileUploadStateWidget(
                        fileState: uploads.first,
                        mediaPreviewBuilder: (file, mediaType) {
                          if (mediaType == MediaType.video) {
                            return VideoPreview(file);
                          }
                          throw UnsupportedError('Unsupported media type');
                        },
                        onRemoveUpload: (attachment) {
                          return uploadController.removeUpload(attachment);
                        },
                        onCancelUpload: (attachment) {
                          uploadController.cancelUpload(attachment);
                        },
                        onRetryUpload: (attachment) async {
                          return uploadController.uploadImage(attachment);
                        }),
                  )
                : const SizedBox.shrink();
          },
        ),
      ),
      TextButton(
        child: const Text("Create"),
        onPressed: () async {
          print("Creating project");
          final client = FeedProvider.of(context).bloc.client;
          final videoUrl =
              uploadController.getMediaUris()!.first.uri.toString();
          print("video_url $videoUrl");
          await FeedProvider.of(context).bloc.onAddActivity(
              feedGroup: 'video_timeline',
              verb: "add",
              data: {
                "description": projectDescController.text,
                "project_name": projectNameController.text,
                "video_url": videoUrl,
              },
              object: "video");
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      )
    ]);
  }
}

class UploadFileButton extends StatelessWidget {
  const UploadFileButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.file_copy),
          onPressed: () async {
            final ImagePicker _picker = ImagePicker();
            final XFile? video = await _picker.pickVideo(
              source: ImageSource.gallery,
            );

            if (video != null) {
              await FeedProvider.of(context)
                  .bloc
                  .uploadController
                  .uploadMedia(AttachmentFile(path: video.path));
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cancelled')));
            }
          },
        ),
        Text(
          'Add a video',
          style: Theme.of(context).textTheme.caption,
        ),
      ],
    );
  }
}

String formatPublishedDate(DateTime publishedDate) =>
    timeago.format(publishedDate);

class ReviewProjectModel {
  final EnrichedActivity activity;
  final int reactionCounts;
  final String projectName;
  final String authorName;
  final DateTime publishedDate;
  final String description;
  final String videoUrl;
  ReviewProjectModel({
    required this.activity,
    required this.reactionCounts,
    required this.projectName,
    required this.authorName,
    required this.publishedDate,
    required this.description,
    required this.videoUrl,
  });
  factory ReviewProjectModel.fromActivity(EnrichedActivity activity) {
    final projectName = activity.extraData!["project_name"] as String;
    final reactionCounts = activity.reactionCounts?["comment"] ?? 0;
    final authorName = activity.actor!.data!["full_name"] as String;
    final publishedDate = activity.time!; //. DateTime(2022, 05, 02);
    final videoUrl =
        activity.extraData!['video_url'] as String; //"Gordon Hayes",
    final description =
        activity.extraData!["description"] as String; // "this is a descrption
    return ReviewProjectModel(
        activity: activity,
        authorName: authorName,
        description: description,
        projectName: projectName,
        publishedDate: publishedDate,
        reactionCounts: reactionCounts,
        videoUrl: videoUrl);
  }
}

class ProjectPreview extends StatelessWidget {
  final ReviewProjectModel reviewModel;
  const ProjectPreview({Key? key, required this.reviewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ReviewProject(
                        reviewProjectModel: reviewModel,
                      )));
        },
        child: Column(
          children: [
            Image.network(
              'https://placeimg.com/640/480/any',
              fit: BoxFit.fill,
            ),
            Text(
              reviewModel.projectName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  reviewModel.authorName,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.comment_rounded,
                        size: 14,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("${reviewModel.reactionCounts}"),
                      ),
                    ],
                  ),
                )
              ],
            )

            // Container(color: Colors.blueGrey)
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      margin: const EdgeInsets.all(10),
    );
  }
}

class ReviewProject extends StatefulWidget {
  const ReviewProject({Key? key, required this.reviewProjectModel})
      : super(key: key);
  final ReviewProjectModel reviewProjectModel;

  @override
  State<ReviewProject> createState() => _ReviewProjectState();
}

class _ReviewProjectState extends State<ReviewProject> {
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

class CommentListViewBuilder extends StatelessWidget {
  const CommentListViewBuilder(
      {Key? key,
      ChewieController? chewieController,
      required this.lookupValue,
      this.lookupAttr = LookupAttribute.activityId})
      : _chewieController = chewieController,
        super(key: key);
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
        return CommentListView(
            lookupValue: lookupValue,
            chewieController: _chewieController,
            reactions: reactions);
      },
    );
  }
}

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

class FrameCommentModel {
  final int? timestamp;
  final DateTime date;
  final String text;
  final String username;
  final String avatarUrl;
  final int? numberOfLikes;
  final int? numberOfComments;
  final String lookupValue;
  final bool isLikedByUser;
  const FrameCommentModel({
    this.timestamp,
    required this.date,
    required this.text,
    required this.username,
    required this.avatarUrl,
    this.numberOfLikes,
    this.numberOfComments,
    required this.lookupValue,
    required this.isLikedByUser,
  });

  factory FrameCommentModel.fromReaction(
      Reaction reaction, String lookupValue) {
    final username =
        reaction.user!.data!['full_name'] as String; //"Gordon Hayes",
    final avatarUrl = reaction.user!.data!['profile_image'] as String? ??
        "https://i.pravatar.cc/300"; //"https://i.pravatar.cc/300"
    final timestamp = reaction.data!["timestamp"] as int?; //12
    final text = reaction.data!["text"]
        as String; // "Need to fix weird animation thing here"
    final date = reaction.createdAt!; // DateTime(2022, 04, 02),
    final numberOfComments = reaction.childrenCounts?['comment'];
    final isLikedByUser = (reaction.ownChildren?['like']?.length ?? 0) > 0;
    final numberOfLikes = reaction.childrenCounts?['like'];
    return FrameCommentModel(
      date: date,
      text: text,
      username: username,
      avatarUrl: avatarUrl,
      lookupValue: lookupValue,
      isLikedByUser: isLikedByUser,
      numberOfComments: numberOfComments,
      numberOfLikes: numberOfLikes,
      timestamp: timestamp,
    );
  }
}

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
  final Future<void> Function(int timestamp)? onSeekTo;
  final Future<void> Function(String reply) onReply;
  final Future<void> Function(bool isLikedByUser) onToggleLikeReaction;
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

class FrameAvatar extends StatelessWidget {
  const FrameAvatar({
    Key? key,
    required this.url,
  }) : super(key: key);
  final String url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        backgroundImage: NetworkImage(
          url,
        ),
        radius: 14);
  }
}

// ignore: avoid_classes_with_only_static_members
class AppTheme {
  static final light = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(secondary: Colors.blue),
    disabledColor: Colors.grey.shade400,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(secondary: Colors.deepPurple),
    disabledColor: Colors.grey.shade400,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

Future<void> main() async {
  const apiKey = String.fromEnvironment('api_key');
  const userToken = String.fromEnvironment('user_token');
  final client = StreamFeedClient(apiKey);

  await client.setUser(
    const User(
      id: 'GroovinChip',
      data: {
        'handle': '@GroovinChip',
        'first_name': 'Reuben',
        'last_name': 'Turner',
        'full_name': 'Reuben Turner',
        'profile_image': 'https://avatars.githubusercontent.com/u/4250470?v=4',
      },
    ),
    const Token(userToken),
  );
  const feedGroup =
      'video_timeline'; //or maybe we could call this something more meaningful like video_feed
  // client.flatFeed('video_timeline').addActivity(Activity(
  //     verb: "add",
  //     extraData: {
  //       "description": "this is a description",
  //       "project_name": "streamagram.mov",
  //       "video_url":
  //           "https://assets.mixkit.co/videos/preview/mixkit-daytime-city-traffic-aerial-view-56-large.mp4",
  //     },
  //     actor: client.currentUser!.ref,
  //     object: "video",
  //     time: DateTime.now()));
  runApp(
    StreamFrame(
      client: client,
    ),
  );
}

String convertDuration(Duration timestamp) {
  final minutes = timestamp.inMinutes % 60;
  final seconds = timestamp.inSeconds % 60;
  return '$minutes:$seconds';
}

class VideoPreview extends StatefulWidget {
  const VideoPreview(this.file, {Key? key}) : super(key: key);
  final AttachmentFile file;

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
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
