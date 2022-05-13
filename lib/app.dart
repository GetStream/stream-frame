import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/theme.dart';

/// The App that make [FeedBloc] available in the context
/// through the [FeedProvider] InheritedWidget.
class StreamFrameApp extends StatefulWidget {
  const StreamFrameApp({
    Key? key,
    this.title = 'Chewie Demo',
    required this.client,
    required this.home,
  }) : super(key: key);
  final StreamFeedClient client;
  final String title;
  final Widget home;

  @override
  State<StatefulWidget> createState() {
    return _StreamFrameAppState();
  }
}

class _StreamFrameAppState extends State<StreamFrameApp> {
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
        home: widget.home);
    return materialApp;
  }
}
