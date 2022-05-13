
import 'package:timeago/timeago.dart' as timeago;

String convertDuration(Duration timestamp) {
  final minutes = timestamp.inMinutes % 60;
  final seconds = timestamp.inSeconds % 60;
  return '$minutes:$seconds';
}

String formatPublishedDate(DateTime publishedDate) =>
    timeago.format(publishedDate);
