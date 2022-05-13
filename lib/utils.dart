import 'package:timeago/timeago.dart' as timeago;

/// Utils used in [VideoPositionIndicator] to convert from [Duration] to a string
String convertDuration(Duration timestamp) {
  final minutes = timestamp.inMinutes % 60;
  final seconds = timestamp.inSeconds % 60;
  return '$minutes:$seconds';
}

/// Format a [DateTime] to a a fuzzy string
String formatPublishedDate(DateTime publishedDate) =>
    timeago.format(publishedDate);
