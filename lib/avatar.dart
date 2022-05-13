import 'package:flutter/material.dart';

/// A NetworkImage CircleAvatar
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
