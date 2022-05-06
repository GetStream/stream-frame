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
        home: Projects());
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
          child: Icon(
            Icons.add,
          )),
      appBar: AppBar(
        title: Text(
          "Stream Frame",
        ),
      ),
      body: FlatFeedCore(
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

            //TODO: add a step in between (PreviewProject(commentNumber,preview?)) that Navigator.push to ReviewProject
            itemBuilder: (context, index) => ProjectPreview(
              activity: activities[index],
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
          );
        },
      ),
    );
  }

  static Route<Object?> _dialogBuilder(
      BuildContext context, Object? arguments) {
    return DialogRoute<void>(
      context: context,
      builder: (BuildContext context) => NewProjectDialog(),
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
    return SimpleDialog(title: Text('New project'), children: [
      Padding(
        padding: EdgeInsets.all(8.0),
        child: TextField(
            controller: projectNameController,
            decoration: InputDecoration.collapsed(
              hintText: "Enter Project Name",
            )),
      ),
      Padding(
        padding: EdgeInsets.all(8.0),
        child: TextField(
            controller: projectDescController,
            decoration: InputDecoration.collapsed(
              hintText: "Enter Project Description",
            )),
      ),
      UploadFileButton(),
      Container(
        width: double.maxFinite,
        child: UploadListCore(
          uploadController: uploadController,
          loadingBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          uploadsErrorBuilder: (error) => Center(child: Text(error.toString())),
          uploadsBuilder: (context, uploads) {
            return SizedBox(
              height: 100,
              child: ListView.separated(
                separatorBuilder: (context, index) => const Divider(),
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: uploads.length,
                itemBuilder: (context, index) => FileUploadStateWidget(
                    fileState: uploads[index],
                    onRemoveUpload: (attachment) {
                      return uploadController.removeUpload(attachment);
                    },
                    onCancelUpload: (attachment) {
                      uploadController.cancelUpload(attachment);
                    },
                    onRetryUpload: (attachment) async {
                      return uploadController.uploadImage(attachment);
                    }),
              ),
            );
          },
        ),
      ),
      TextButton(
          onPressed: () {
            print("Creating project");
            final client = FeedProvider.of(context).bloc.client;

            client.flatFeed('video_timeline').addActivity(Activity(
                verb: "add",
                extraData: {
                  "description": projectDescController.text,
                  "project_name": projectNameController.text,
                  "video_url":
                      uploadController.getMediaUris()!.first.uri.toString(),
                },
                actor: client.currentUser!.ref,
                object: "video",
                time: DateTime.now()));
          },
          child: Text("Create"))
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
          icon: const Icon(Icons.file_copy),
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

class ProjectPreview extends StatelessWidget {
  final EnrichedActivity activity;
  const ProjectPreview({Key? key, required this.activity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectName = activity.extraData!["project_name"] as String;
    final commentNumber = activity.reactionCounts?["comment"] as int? ?? 0;
    final authorName = activity.actor!.data!["full_name"] as String;
    final publishedDate = activity.time!; //. DateTime(2022, 05, 02);
    return Card(
      semanticContainer: true,
      // color: Colors.purple,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ReviewProject(
                      activity: activity,
                      reactionCounts: commentNumber,
                      videoUrl: activity.extraData!['video_url'] as String,
                      projectName: projectName, // "streamagram.mov",
                      authorName: authorName, //"Gordon Hayes",
                      description: activity.extraData!["description"]
                          as String, // "this is a descrption",
                      publishedDate: publishedDate)));
        },
        child: Column(
          children: [
            Image.network(
              'https://placeimg.com/640/480/any',
              fit: BoxFit.fill,
            ),
            Text(
              projectName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  authorName,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment_rounded,
                        size: 14,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("$commentNumber"),
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
      margin: EdgeInsets.all(10),
    );
  }
}

class ReviewProject extends StatefulWidget {
  const ReviewProject({
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
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text(widget.authorName,
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(" uploaded ${formatPublishedDate(widget.publishedDate)}",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold))
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.description,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
            child: Text("${widget.reactionCounts} Comments"),
          ),
          Expanded(
            child: CommentListView(
              key: Key("${widget.activity.id}_comments"),
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
                            .data?["profile_image"] as String? ??
                        "https://i.pravatar.cc/300"),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: textController,
                      decoration: InputDecoration.collapsed(
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.timer),
                      SizedBox(
                        width: 12,
                      ),
                      //TODO: update this value continuously (in a performant way) from
                      // _chewieController!.videoPlayerController.value.position
                      //save it in a field so it's usable by as timestamp param for
                      //onAddReaction
                      Text(convertDuration(Duration(seconds: 2))),
                    ],
                  ),
                ),
                Container(
                  child: TextButton(
                      onPressed: () {
                        FeedProvider.of(context).bloc.onAddReaction(
                          kind: "comment",
                          activity: activity,
                          feedGroup: 'video_timeline',
                          data: {
                            "timestamp": 12, //TODO: unhardcode this
                            "text": textController.text, //_
                          },
                        );
                        textController.clear();
                      },
                      child: Text("Send")),
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
      emptyBuilder: (context) => Offstage(),
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
                username: reactions[index].user!.data!['full_name']
                    as String, //"Gordon Hayes",
                avatarUrl: reactions[index].user!.data!['profile_image']
                        as String? ??
                    "https://i.pravatar.cc/300", //"https://i.pravatar.cc/300"
                timestamp: reactions[index].data!["timestamp"] as int?, //12
                text: reactions[index].data!["text"]
                    as String, // "Need to fix weird animation thing here"
                date: reactions[index].createdAt!, // DateTime(2022, 04, 02),

                onSeekTo: _chewieController != null
                    ? (int timestamp) {
                        _chewieController?.seekTo(Duration(seconds: timestamp));
                      }
                    : null));
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
  }) : super(key: key);
  final LookupAttribute lookupAttr;
  final Reaction reaction;
  final EnrichedActivity activity;
  final int? timestamp;
  final DateTime date;
  final String text;
  final String username;
  final String avatarUrl;
  final String lookupValue;
  final void Function(int timestamp)? onSeekTo;

  @override
  State<FrameComment> createState() => _FrameCommentState();
}

class _FrameCommentState extends State<FrameComment> {
  bool showTextField = false;
  final replyController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final isLikedByUser =
        (widget.reaction.ownChildren?['like']?.length ?? 0) > 0;

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
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                            : "",
                        style: TextStyle(
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
                : SizedBox(width: 45),
            Text(widget.text),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  showTextField = !showTextField;
                });
              },
              child: Text(
                "Reply",
                style: TextStyle(fontSize: 14),
              ),
            ),
            IconButton(
              onPressed: () {
                print("like");
                if (isLikedByUser) {
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
              icon: isLikedByUser
                  ? const Icon(Icons.thumb_up, size: 14)
                  : const Icon(Icons.thumb_up_outlined, size: 14),
            ),
            if (widget.reaction.childrenCounts?['like'] != null &&
                widget.reaction.childrenCounts!['like']!.toInt() > 0)
              Text(
                widget.reaction.childrenCounts!['like'].toString(),
                style: TextStyle(fontSize: 14),
              ),
            if (showTextField)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ReplyTextField(replyController: replyController),
              ),
            if (showTextField)
              IconButton(
                icon: Icon(
                  Icons.send,
                  size: 12,
                ),
                onPressed: () async {
                  await FeedProvider.of(context).bloc.onAddChildReaction(
                    kind: "comment",
                    reaction: widget.reaction,
                    activity: widget.activity,
                    lookupAttr: widget.lookupAttr,
                    lookupValue: widget.lookupValue,
                    data: {
                      "text": replyController.text,
                    },
                  );
                  replyController.clear();
                },
              )
          ],
        ),
        Row(
          // mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 40,
            ),
            Expanded(
              child: CommentListView(
                key: Key("${widget.reaction.id}_comments"),
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
  final feedGroup =
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
