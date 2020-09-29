import 'package:epub_renderer/src/readers/android_reader.dart';
import 'package:epub_renderer/src/readers/ios_reader.dart';
import 'package:epub_renderer/src/readers/reader.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class EpubRenderer extends StatelessWidget {
  final String epubFilePath;
  final String epubUrl;
  final String apiKey;
  final bool isAudioEnabled;
  final double minReadTime;
  final OnReaderEvent onEvent;

  const EpubRenderer({
    @required this.epubFilePath,
    @required this.epubUrl,
    @required this.apiKey,
    @required this.isAudioEnabled,
    @required this.minReadTime,
    @required this.onEvent,
  });

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return IOSReader(
          epubUrl: epubUrl,
          apiKey: apiKey,
          isAudioEnabled: isAudioEnabled,
          minReadTime: minReadTime,
          onEvent: onEvent,
        );
      case TargetPlatform.android:
        return AndroidReader(
          epubFilePath: epubFilePath,
          isAudioEnabled: isAudioEnabled,
          minReadTime: minReadTime,
          onEvent: onEvent,
        );
      default:
        throw 'Unsupported platform type: $defaultTargetPlatform';
    }
  }
}
