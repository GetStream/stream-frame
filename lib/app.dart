import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/theme.dart';

/// The App that make [FeedBloc] available in the context
/// through the [FeedProvider] Inherited
class StreamFrameApp extends StatelessWidget {
  const StreamFrameApp({
    Key? key,
    required this.client,
    required this.home,
  }) : super(key: key);
  final StreamFeedClient client;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => FeedProvider(
        bloc: FeedBloc(
          client: client,
        ),
        child: child!,
      ),
      title: 'Stream Frame',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: home,
    );
  }
}
