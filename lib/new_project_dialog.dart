import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:stream_frame/upload_file_picker.dart';
import 'package:stream_frame/video.dart';

class NewProjectDialog extends StatelessWidget {
  const NewProjectDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectNameController = TextEditingController();
    final projectDescController = TextEditingController();
    final uploadController = FeedProvider.of(context).bloc.uploadController;
    return SimpleDialog(title: const Text('New project'), children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: projectNameController,
            decoration: const InputDecoration.collapsed(
              hintText: "Enter Project Name",
            )),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: projectDescController,
            decoration: const InputDecoration.collapsed(
              hintText: "Enter Project Description",
            )),
      ),
      const UploadFilePicker(),
      SizedBox(
        width: double.maxFinite,
        child: UploadListCore(
          uploadController: uploadController,
          loadingBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          uploadsErrorBuilder: (error) => Center(child: Text(error.toString())),
          uploadsBuilder: (context, uploads) {
            return uploads.isNotEmpty
                ? SizedBox(
                    width: double.maxFinite,
                    height: 200,
                    child: FileUploadStateWidget(
                        fileState: uploads.first,
                        mediaPreviewBuilder: (file, mediaType) {
                          if (mediaType == MediaType.video) {
                            return VideoPreviewCard(file);
                          }
                          throw UnsupportedError('Unsupported media type');
                        },
                        onRemoveUpload: (attachment) {
                          return uploadController.removeUpload(attachment);
                        },
                        onCancelUpload: (attachment) {
                          uploadController.cancelUpload(attachment);
                        },
                        onRetryUpload: (attachment) async {
                          return uploadController.uploadImage(attachment);
                        }),
                  )
                : const SizedBox.shrink();
          },
        ),
      ),
      TextButton(
        child: const Text("Create"),
        onPressed: () async {
          final videoUrl =
              uploadController.getMediaUris()!.first.uri.toString();

          await FeedProvider.of(context).bloc.onAddActivity(
              feedGroup: 'video_timeline',
              verb: "add",
              data: {
                "description": projectDescController.text,
                "project_name": projectNameController.text,
                "video_url": videoUrl,
              },
              object: "video",
              time: DateTime.now());
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      )
    ]);
  }
}
