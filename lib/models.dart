import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';

/// A model to represent a comment body
/// it's used in [CommentListView], [FrameAvatar] and [FrameComment]
class FrameCommentModel {
  final int? timestamp;
  final DateTime date;
  final String text;
  final String username;
  final String avatarUrl;
  final int? numberOfLikes;
  final int? numberOfComments;
  final String lookupValue;
  final bool isLikedByUser;
  const FrameCommentModel({
    this.timestamp,
    required this.date,
    required this.text,
    required this.username,
    required this.avatarUrl,
    this.numberOfLikes,
    this.numberOfComments,
    required this.lookupValue,
    required this.isLikedByUser,
  });

  factory FrameCommentModel.fromReaction(
      Reaction reaction, String lookupValue) {
    final username = reaction.user!.data!['full_name'] as String;
    final avatarUrl = reaction.user!.data!['profile_image'] as String? ??
        "https://i.pravatar.cc/300";
    final timestamp = reaction.data!["timestamp"] as int?;
    final text = reaction.data!["text"] as String;
    final date = reaction.createdAt!;
    final numberOfComments = reaction.childrenCounts?['comment'];
    final isLikedByUser = (reaction.ownChildren?['like']?.length ?? 0) > 0;
    final numberOfLikes = reaction.childrenCounts?['like'];
    return FrameCommentModel(
      date: date,
      text: text,
      username: username,
      avatarUrl: avatarUrl,
      lookupValue: lookupValue,
      isLikedByUser: isLikedByUser,
      numberOfComments: numberOfComments,
      numberOfLikes: numberOfLikes,
      timestamp: timestamp,
    );
  }
}

/// A model to represent a review project
/// it's used [ProjectPreviewBuilder], [ReviewProjectPage]
class ReviewProjectModel {
  final EnrichedActivity activity;
  final int reactionCounts;
  final String projectName;
  final String authorName;
  final DateTime publishedDate;
  final String description;
  final String videoUrl;

  ReviewProjectModel({
    required this.activity,
    required this.reactionCounts,
    required this.projectName,
    required this.authorName,
    required this.publishedDate,
    required this.description,
    required this.videoUrl,
  });

  factory ReviewProjectModel.fromActivity(EnrichedActivity activity) {
    final projectName = activity.extraData!["project_name"] as String;
    final reactionCounts = activity.reactionCounts?["comment"] ?? 0;
    final authorName = activity.actor!.data!["full_name"] as String;
    final publishedDate = activity.time!;
    final videoUrl = activity.extraData!['video_url'] as String;
    final description = activity.extraData!["description"] as String;
    return ReviewProjectModel(
        activity: activity,
        authorName: authorName,
        description: description,
        projectName: projectName,
        publishedDate: publishedDate,
        reactionCounts: reactionCounts,
        videoUrl: videoUrl);
  }
}
