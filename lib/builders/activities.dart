
import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/models.dart';
import 'package:stream_frame/project_preview_card.dart';

class ProjectPreviewBuilder extends StatelessWidget {
  const ProjectPreviewBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatFeedCore(
      feedGroup: 'video_timeline',
      userId: FeedProvider.of(context).bloc.currentUser!.id,
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      emptyBuilder: (context) =>
          const Center(child: Text('No video to review')),
      errorBuilder: (context, error) => Center(
        child: Text(error.toString()),
      ),
      limit: 10,
      flags: EnrichmentFlags().withReactionCounts().withOwnReactions(),
      feedBuilder: (context, activities) {
        return GridView.builder(
          itemCount: activities.length,
          itemBuilder: (context, index) => ProjectPreviewCard(
            reviewModel: ReviewProjectModel.fromActivity(activities[index]),
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
        );
      },
    );
  }
}
