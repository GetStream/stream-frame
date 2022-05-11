import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';
import 'package:video_player/video_player.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({Key? key}) : super(key: key);

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _projectNameController = TextEditingController();
  final _projectDescController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final uploadController = FeedProvider.of(context).bloc.uploadController;
    return SimpleDialog(title: const Text('New project'), children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: _projectNameController,
            decoration: const InputDecoration.collapsed(
              hintText: 'Enter Project Name',
            )),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: _projectDescController,
            decoration: const InputDecoration.collapsed(
              hintText: 'Enter Project Description',
            )),
      ),
      const _UploadFileButton(),
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
                            return _VideoPreview(file);
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
        child: const Text('Create'),
        onPressed: () async {
          print('Creating project');
          final videoUrl =
              uploadController.getMediaUris()!.first.uri.toString();
          print('video_url $videoUrl');
          await FeedProvider.of(context).bloc.onAddActivity(
                feedGroup: 'video_timeline',
                verb: 'add',
                data: {
                  'description': _projectDescController.text,
                  'project_name': _projectNameController.text,
                  'video_url': videoUrl,
                },
                object: 'video',
              );
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      )
    ]);
  }
}

class _UploadFileButton extends StatelessWidget {
  const _UploadFileButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.file_copy),
          onPressed: () async {
            final ImagePicker _picker = ImagePicker();
            final XFile? video = await _picker.pickVideo(
              source: ImageSource.gallery,
            );

            if (video != null) {
              final bytes = await video.readAsBytes();
              await FeedProvider.of(context)
                  .bloc
                  .uploadController
                  .uploadMedia(AttachmentFile(
                    bytes: bytes,
                  ));
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cancelled')));
            }
          },
        ),
        Text(
          'Add a video',
          style: Theme.of(context).textTheme.caption,
        ),
      ],
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview(this.file, {Key? key}) : super(key: key);
  final AttachmentFile file;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  @override
  void initState() {
    super.initState();

    initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController =
        VideoPlayerController.file(File(widget.file.path!));

    await _videoPlayerController.initialize();
    _createChewieController();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 5,
      margin: const EdgeInsets.all(5),
      child: _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(
              controller: _chewieController!,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Loading'),
              ],
            ),
    );
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
    );
  }
}
