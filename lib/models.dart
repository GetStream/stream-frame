
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';

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
    final username =
        reaction.user!.data!['full_name'] as String; //"Gordon Hayes",
    final avatarUrl = reaction.user!.data!['profile_image'] as String? ??
        "https://i.pravatar.cc/300"; //"https://i.pravatar.cc/300"
    final timestamp = reaction.data!["timestamp"] as int?; //12
    final text = reaction.data!["text"]
        as String; // "Need to fix weird animation thing here"
    final date = reaction.createdAt!; // DateTime(2022, 04, 02),
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
    final publishedDate = activity.time!; //. DateTime(2022, 05, 02);
    final videoUrl =
        activity.extraData!['video_url'] as String; //"Gordon Hayes",
    final description =
        activity.extraData!["description"] as String; // "this is a descrption
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