import 'package:epub_renderer/src/readers/reader.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSReader extends StatefulWidget implements Reader {
  final String epubUrl;
  final String apiKey;
  final bool isAudioEnabled;
  final double minReadTime;
  final OnReaderEvent onEvent;

  const IOSReader({
    @required this.epubUrl,
    @required this.apiKey,
    @required this.isAudioEnabled,
    @required this.minReadTime,
    @required this.onEvent,
  });

  @override
  State<StatefulWidget> createState() => _IOSReaderState();
}

class _IOSReaderState extends State<IOSReader> {
  MethodChannel _channel;

  void _setupDelegates() {
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'bookDidLoad':
          final didFail = call.arguments['success'] as bool;
          widget.onEvent(ReaderEvent.didLoad, didFail);
          break;
        case 'didMoveToPage':
          final destinationPage = call.arguments['page'] as int;
          widget.onEvent(ReaderEvent.didChangePage, destinationPage);
          break;
        case 'didFinishMediaAtPage':
          final page = call.arguments['page'] as int;
          widget.onEvent(ReaderEvent.didFinishPageMedia, page);
          break;
        default:
          throw 'Call $call not implemented';
      }

      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: UiKitView(
          key: UniqueKey(),
          viewType: 'epub_renderer_view',
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: {
            'EpubUrl': widget.epubUrl,
            'AuthToken': widget.apiKey,
            'IsAudioEnabled': widget.isAudioEnabled,
            'MinReadTime': widget.minReadTime,
          },
          onPlatformViewCreated: (id) {
            _channel = MethodChannel('epub_renderer_view_$id');
            _setupDelegates();
          },
        ),
      ),
    );
  }
}
