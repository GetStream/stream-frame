import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/comments.dart';

class CommentListViewBuilder extends StatelessWidget {
  const CommentListViewBuilder({
    Key? key,
    ChewieController? chewieController,
    required this.lookupValue,
    this.lookupAttr = LookupAttribute.activityId,
  })  : _chewieController = chewieController,
        super(key: key);
  final ChewieController? _chewieController;
  final LookupAttribute lookupAttr;
  final String lookupValue;

  @override
  Widget build(BuildContext context) {
    return ReactionListCore(
      lookupValue: lookupValue,
      lookupAttr: lookupAttr,
      kind: 'comment',
      flags: EnrichmentFlags()
          .withOwnChildren()
          .withOwnReactions()
          .withReactionCounts(),
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      emptyBuilder: (context) => const Offstage(),
      errorBuilder: (context, error) => Center(
        child: Text(error.toString()),
      ),
      reactionsBuilder: (BuildContext context, List<Reaction> reactions) {
        return CommentListView(
            lookupValue: lookupValue,
            chewieController: _chewieController,
            reactions: reactions);
      },
    );
  }
}
