import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/new_project_dialog.dart';
import 'package:stream_frame/project_review_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).restorablePush(_dialogBuilder);
          },
          child: const Icon(Icons.add)),
      appBar: AppBar(
        title: const Text('Stream Frame'),
      ),
      body: FlatFeedCore(
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

            //TODO: add a step in between (PreviewProject(commentNumber,preview?)) that Navigator.push to ReviewProject
            itemBuilder: (context, index) => _ProjectPreview(
              activity: activities[index],
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
          );
        },
      ),
    );
  }

  static Route<Object?> _dialogBuilder(
      BuildContext context, Object? arguments) {
    return DialogRoute<void>(
      context: context,
      builder: (BuildContext context) => const NewProjectDialog(),
    );
  }
}

String formatPublishedDate(DateTime publishedDate) =>
    timeago.format(publishedDate);

class _ProjectPreview extends StatelessWidget {
  const _ProjectPreview({Key? key, required this.activity}) : super(key: key);

  final EnrichedActivity activity;

  @override
  Widget build(BuildContext context) {
    final projectName = activity.extraData!['project_name'] as String;
    final commentNumber = activity.reactionCounts?['comment'] ?? 0;
    final authorName = activity.actor!.data!['full_name'] as String;
    final publishedDate = activity.time!; //. DateTime(2022, 05, 02);
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectReviewPage(
                  activity: activity,
                  reactionCounts: commentNumber,
                  videoUrl: activity.extraData!['video_url'] as String,
                  projectName: projectName,
                  authorName: authorName,
                  description: activity.extraData!['description'] as String,
                  publishedDate: publishedDate),
            ),
          );
        },
        child: Column(
          children: [
            Image.network(
              'https://picsum.photos/200/300',
              fit: BoxFit.fill,
            ),
            Text(
              projectName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  authorName,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.comment_rounded,
                        size: 14,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('$commentNumber'),
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      margin: const EdgeInsets.all(10),
    );
  }
}
