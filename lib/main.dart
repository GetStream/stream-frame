import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/app.dart';
import 'package:stream_frame/projects_page.dart';

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

  runApp(
    StreamFrameApp(
      client: client,
      home: const ProjectsPage(),
    ),
  );
}
