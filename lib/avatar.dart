import 'package:flutter/material.dart';

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
