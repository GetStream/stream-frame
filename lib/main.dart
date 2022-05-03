import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
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
        flags: EnrichmentFlags()
          ..withReactionCounts()
          ..withOwnReactions(),
        feedBuilder: (context, activities) {
          print(activities);
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
                Row(
                  children: [
                    Icon(
                      Icons.comment_rounded,
                      size: 14,
                    ),
                    Text("$commentNumber"),
                  ],
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
  final textController = TextEditingController();
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
          "Stream Frame",
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
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
          CommentListView(
            activity: widget.activity,
            chewieController: _chewieController,
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
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
                                  activity: widget.activity,
                                  feedGroup: 'video_timeline',
                                  data: {
                                    "timestamp": 12, //TODO: unhardcode this
                                    "text": textController.text, //_
                                  },
                                );

                                //                     Reaction(
                                //   user: User(data: {
                                //     "full_name": "Gordon Hayes",
                                //     "profile_image": "https://i.pravatar.cc/300"
                                //   }),
                                //   data: {
                                //     "timestamp": 12,
                                //     "text": "Need to fix weird animation thing here",
                                //   },
                                //   createdAt: DateTime(2022, 04, 02),
                                // )
                              },
                              child: Text("Send")),
                        )
                      ],
                    ),
                  ) //convertDuration(position)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommentListView extends StatelessWidget {
  const CommentListView({
    Key? key,
    required ChewieController? chewieController,
    required this.activity,
  })  : _chewieController = chewieController,
        super(key: key);
  final EnrichedActivity activity;
  final ChewieController? _chewieController;

  @override
  Widget build(BuildContext context) {
    return ReactionListCore(
      lookupValue: activity.id!,
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      emptyBuilder: (context) => Offstage(),
      errorBuilder: (context, error) => Center(
        child: Text(error.toString()),
      ),
      reactionsBuilder: (BuildContext context, List<Reaction> reactions) {
        return ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: reactions.length,
            itemBuilder: (context, index) => FrameComment(
                reaction: reactions[index],
                activity: activity,
                username: reactions[index].user!.data!['full_name']
                    as String, //"Gordon Hayes",
                avatarUrl: reactions[index].user!.data!['profile_image']
                        as String? ??
                    "https://i.pravatar.cc/300", //"https://i.pravatar.cc/300"
                timestamp: reactions[index].data!["timestamp"] as int, //12
                text: reactions[index].data!["text"]
                    as String, // "Need to fix weird animation thing here"
                date: reactions[index].createdAt!, // DateTime(2022, 04, 02),

                onSeekTo: (int timestamp) {
                  _chewieController!.seekTo(Duration(seconds: timestamp));
                }));
      },
    );
  }
}

class FrameComment extends StatelessWidget {
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
  }) : super(key: key);
  final Reaction reaction;
  final EnrichedActivity activity;
  final int timestamp;
  final DateTime date;
  final String text;
  final String username;
  final String avatarUrl;
  final void Function(int timestamp) onSeekTo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FrameAvatar(url: avatarUrl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  username,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  formatPublishedDate(date),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Text(
                  timestampConverted,
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              onTap: () {
                onSeekTo(timestamp);
              },
            ),
            Text(text),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {
                // FeedProvider.of(context).bloc.onAddChildReaction(
                //       kind: "comment",
                //       activity: activity,
                //       data: {
                //         "timestamp": 12, //TODO: unhardcode this
                //         "text": replyController.text, //_
                //       },
                //       reaction: reaction,
                //     );
                print("reply");
                //TODOs: - onAddChildReaction comment
                //      - toggle TextField
              },
              child: Text(
                "Reply",
                style: TextStyle(fontSize: 14),
              ),
            ),
            IconButton(
              onPressed: () {
                print("like");
                FeedProvider.of(context).bloc.onAddChildReaction(
                    kind: 'like', reaction: reaction, activity: activity);
              },
              icon: Icon(
                Icons.thumb_up_outlined,
                size: 12,
              ),
            )
          ],
        )
      ],
    );
  }

  String get timestampConverted {
    final duration = Duration(seconds: timestamp);
    return convertDuration(duration);
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
        radius: 18);
  }
}

// ignore: avoid_classes_with_only_static_members
class AppTheme {
  static final light = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(secondary: Colors.red),
    disabledColor: Colors.grey.shade400,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(secondary: Colors.red),
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
  // client.flatFeed(feedGroup).addActivity(Activity(
  //     verb: "add",
  //     extraData: {
  //       "description": "this is a descrption",
  //       "project_name": "streamagram.mov",
  //       "video_url":
  //           "https://assets.mixkit.co/videos/preview/mixkit-daytime-city-traffic-aerial-view-56-large.mp4"
  //       //TODO: interface with a small form+ file picker + upload core to create a new project
  //     },
  //     actor: client.currentUser!.ref,
  //     object: "video",
  //     time: DateTime(2022, 05, 02)));
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
