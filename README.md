<h1 align="center">Flutter Frame Clone (Stream-frame)</h1>

<p align="center">
    <a href="https://pub.dev/packages/stream_feed_flutter_core"><img src="https://img.shields.io/pub/v/stream_feed_flutter_core?include_prereleases" alt="Pub"></a>
    <a href="https://pub.dev/packages/flutter_lints"><img src="https://img.shields.io/badge/style-flutter__lints-blue" alt="style: flutter lints"></a>
    <a href="https://github.com/GetStream/flutter-samples"><img src="https://img.shields.io/badge/flutter-samples-teal.svg?longCache=true" alt="Flutter Samples"></a>
    <a href="https://opensource.org/licenses/Apache-2.0"><img alt="License" src="https://img.shields.io/badge/License-Apache%202.0-blue.svg"/></a>
    <a href="https://getstream.io/"><img src="https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/HayesGordon/e7f3c4587859c17f3e593fd3ff5b13f4/raw/11d9d9385c9f34374ede25f6471dc743b977a914/badge.json" alt="Stream Feeds"></a>
</p>

<p align="center">  
Stream-frame is a demo application showing how to recreate Frame.io using <a href="https://flutter.dev/">Flutter</a> and <a href="https://getstream.io/activity-feeds/">Stream Feeds</a>.
</br>

<p align="center">
<img src="/previews/preview.png" />
</p>

## Tutorials
If you'd like to learn more about this project and how the code is structured, take a look at the companion blog and video.

### Blog Post
- Article detailing a step-by-step guide for this project.

## Previews

## Supported features
- Uploading a video, as part of creating a new video project (activity)
- Commenting on a specific timestamp (reaction)
- Child reactions: like, child comments (i.e. thread)
- Jumping to a timestamp


## Getting Started
These are the steps to run this project locally, with your own Stream Feeds configuration.

### Clone This Repository
```
git clone https://github.com/GetStream/stream-frame
```

### Create Flutter Platform Folders
Run this inside the main folder to generate platform folders.
```
flutter create .
```

### Setup Image Picker Package
Depending on the platform that you're targetting you will need to do some [setup](https://pub.dev/packages/image_picker#installation) for the [image_picker](https://pub.dev/packages/image_picker) Flutter package. At the time of writing this package only supports **Android**, **iOS** and **Web**.

### Add Keys and Tokens
You will also need to add your **Stream API-Key** and **User Frontend Tokens**. These are marked with TODOs in the codebase.

<img src="https://user-images.githubusercontent.com/24237865/138428440-b92e5fb7-89f8-41aa-96b1-71a5486c5849.png" align="right" width="12%"/>

## Stream Feeds Flutter SDK
Stream-agram is built with [Stream Feeds](https://getstream.io/activity-feeds/) for implementing activity feeds.
- [Activity Feeds Tutorial](https://getstream.io/activity-feeds/sdk/flutter/tutorial/) - Basic tutorials for getting started with activity feeds.
- [Stream Feeds Flutter Repository](https://github.com/GetStream/stream-feed-flutter) - Official Flutter SDK for Stream Feeds.
- [Feed Client Documentation](https://getstream.io/activity-feeds/docs/flutter-dart/?language=dart) - Detailed documentation of the Activity Feeds client.

<img src="https://media.giphy.com/media/Dm0KdEtqxhpdkEa6j7/giphy.gif" align="right" width="32%"/>

## Stream Chat Flutter SDK
If you're interested in adding chat functionality to your Frame clone, check out [Stream Chat](https://getstream.io/chat/).
- [Chat Messaging Tutorial](https://getstream.io/chat/flutter/tutorial/) - Basic tutorials for getting started by building a simple messaging app.
- [Stream Chat Flutter repository](https://github.com/GetStream/stream-chat-flutter) - Official Flutter SDK for Stream Chat.
- [Chat Client Documentation](https://getstream.io/chat/docs/flutter-dart/?language=dart) - Full documentation of the Chat client for requesting API calls. 
- [Chat UI Components Documentation and Guides](https://getstream.io/chat/docs/sdk/flutter/) - Full documentation of the Stream UI Components.
- [Sample Application](https://github.com/GetStream/flutter-samples/tree/main/packages/stream_chat_v1) - Official Flutter sample chat application.

## Find this repository useful? 💙
Support it by joining __[stargazers](https://github.com/GetStream/stream-frame/stargazers)__ :star: <br>

# License
```xml
Copyright 2021 Stream.IO, Inc. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

