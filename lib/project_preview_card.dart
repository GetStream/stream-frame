
import 'package:flutter/material.dart';
import 'package:stream_frame/models.dart';
import 'package:stream_frame/review_project_page.dart';

class ProjectPreviewCard extends StatelessWidget {
  final ReviewProjectModel reviewModel;
  const ProjectPreviewCard({Key? key, required this.reviewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ReviewProjectPage(
                        reviewProjectModel: reviewModel,
                      )));
        },
        child: Column(
          children: [
            Image.network(
              'https://placeimg.com/640/480/any',
              fit: BoxFit.fill,
            ),
            Text(
              reviewModel.projectName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  reviewModel.authorName,
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
                        child: Text("${reviewModel.reactionCounts}"),
                      ),
                    ],
                  ),
                )
              ],
            )

            // Container(color: Colors.blueGrey)
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