import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/projects_page.dart';
import 'package:stream_frame/theme.dart';

class StreamFrame extends StatelessWidget {
  const StreamFrame({
    Key? key,
    required this.client,
    this.title = 'Stream-Frame',
    this.platform,
  }) : super(key: key);

  final StreamFeedClient client;
  final String title;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => FeedProvider(
        bloc: FeedBloc(
          client: client,
        ),
        child: child!,
      ),
      title: title,
      theme: AppTheme.light.copyWith(
        platform: platform ?? Theme.of(context).platform,
      ),
      home: const ProjectsPage(),
    );
  }
}
