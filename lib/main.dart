import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';

class StreamFrame extends StatefulWidget {
  const StreamFrame({
    Key? key,
    this.title = 'Chewie Demo',
  }) : super(key: key);

  final String title;

  @override
  State<StatefulWidget> createState() {
    return _StreamFrameState();
  }
}

class _StreamFrameState extends State<StreamFrame> {
  TargetPlatform? _platform;
  late VideoPlayerController _videoPlayerController1;
  late VideoPlayerController _videoPlayerController2;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController1.dispose();
    _videoPlayerController2.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

//TODO: clean this up and take from attachment
  List<String> srcs = [
    "https://assets.mixkit.co/videos/preview/mixkit-daytime-city-traffic-aerial-view-56-large.mp4",
    "https://assets.mixkit.co/videos/preview/mixkit-a-girl-blowing-a-bubble-gum-at-an-amusement-park-1226-large.mp4"
  ];

  Future<void> initializePlayer() async {
    _videoPlayerController1 =
        VideoPlayerController.network(srcs[currPlayIndex]);
    _videoPlayerController2 =
        VideoPlayerController.network(srcs[currPlayIndex]);
    await Future.wait([
      _videoPlayerController1.initialize(),
      _videoPlayerController2.initialize()
    ]);
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
    return MaterialApp(
      title: widget.title,
      theme: AppTheme.light.copyWith(
        platform: _platform ?? Theme.of(context).platform,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "Stream Frame",
          ),
        ),
        body: ReviewProject(
            chewieController: _chewieController,
            projectName: "streamagram.mov",
            authorName: "Gordon Hayes",
            description: "this is a descrption",
            publishedDate: DateTime(2022, 05, 02)),
      ),
    );
  }
}

String formatPublishedDate(DateTime publishedDate) =>
    timeago.format(publishedDate);

class ReviewProject extends StatelessWidget {
  const ReviewProject({
    Key? key,
    required ChewieController? chewieController,
    required this.projectName,
    required this.authorName,
    required this.publishedDate,
    required this.description,
  })  : _chewieController = chewieController,
        super(key: key);
  final String projectName;
  final String authorName;
  final DateTime publishedDate;
  final String description;
  final ChewieController? _chewieController;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          child:
              Text(projectName, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Text(authorName,
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
              Text("Uploaded ${formatPublishedDate(publishedDate)}",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold))
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            description,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
          child: Text("2 Comments"),
        ), //TODO: replace with number for comments from feeds
        CommentListView(chewieController: _chewieController),
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
                      child: FrameAvatar(url: "https://i.pravatar.cc/300"),//TODO: replace with currentUser avatar 
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
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
                            Text(convertDuration(Duration(seconds: 2))),
                          ],
                        ),
                      ),
                      Container(
                        child: TextButton(
                            onPressed: () {
                              print("send");
                              //TODOs: - onAddReaction comment
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
    );
  }
}

class CommentListView extends StatelessWidget {
  const CommentListView({
    Key? key,
    required ChewieController? chewieController,
  })  : _chewieController = chewieController,
        super(key: key);

  final ChewieController? _chewieController;

  @override
  Widget build(BuildContext context) {
    return Column(
      //TODO: replace with flat feed core
      children: [
        Comment(
            username: "Gordon Hayes",
            timestamp: 12,
            text: "Need to fix weird animation thing here",
            date: DateTime(2022, 04, 02),
            onSeekTo: (int timestamp) {
              _chewieController!.seekTo(Duration(seconds: timestamp));
            }),
      ],
    );
  }
}

class Comment extends StatelessWidget {
  const Comment({
    Key? key,
    required this.timestamp,
    required this.text,
    required this.date,
    required this.username,
    required this.onSeekTo,
  }) : super(key: key);
  final int timestamp;
  final DateTime date;
  final String text;
  final String username;
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
              FrameAvatar(
                  url:
                      "https://i.pravatar.cc/300"), //TODO: replace with actual avatar
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
                //TODOs: - onAddChildReaction like
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
          url, //TODO: avatarUrl from stream
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

void main() {
  runApp(
    const StreamFrame(),
  );
}

String convertDuration(Duration timestamp) {
  final minutes = timestamp.inMinutes % 60;
  final seconds = timestamp.inSeconds % 60;
  return '$minutes:$seconds';
}
