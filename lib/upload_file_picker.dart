import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';

/// A file picker that uploads a video to Stream CDN
class UploadVideoPicker extends StatelessWidget {
  const UploadVideoPicker({
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
              await FeedProvider.of(context)
                  .bloc
                  .uploadController
                  .uploadMedia(AttachmentFile(path: video.path));
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
