import 'package:epub_parser/epub_parser.dart';
import 'package:epub_renderer/src/book_page.dart';
import 'package:epub_renderer/src/readers/reader.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

@immutable
class AndroidReader extends StatefulWidget implements Reader {
  final String epubFilePath;
  final bool isAudioEnabled;
  final double minReadTime;
  final OnReaderEvent onEvent;

  const AndroidReader({
    @required this.epubFilePath,
    @required this.isAudioEnabled,
    @required this.minReadTime,
    @required this.onEvent,
  });

  @override
  _AndroidReaderState createState() {
    return _AndroidReaderState();
  }
}

class _AndroidReaderState extends State<AndroidReader> {
  Epub _epub;
  bool _isParsing = true;
  double _progress = 0;
  final _controller = PageController();

  _AndroidReaderState();

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Widget get _progressIndicator {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Loading ePub, please wait'),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            backgroundColor: Colors.grey,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 40,
            value: _progress / 100,
          ),
        ],
      ),
    );
  }

  void _loadEpub() {
    EpubParser.parse(widget.epubFilePath, (progress) {
      setState(() {
        _progress = progress;
      });
    }, (epub) {
      widget.onEvent(ReaderEvent.didLoad, true);
      setState(() {
        _isParsing = false;
        _epub = epub;
      });
    });
  }

  Widget get _book {
    final pages = _epub.chapters.map((chapter) {
      return BookPage(
        UniqueKey(),
        chapter,
        _epub.metadata.highlightClassName,
        widget.isAudioEnabled,
        () async {
          if (widget.isAudioEnabled) {
            widget.onEvent(ReaderEvent.didFinishPageMedia, _controller.page);
            await _controller.nextPage(
              duration: const Duration(milliseconds: 400), // Default transition duration
              curve: Curves.easeInOut, // Default curve
            );
            widget.onEvent(ReaderEvent.didChangePage, _controller.page);
          }
        },
      );
    }).toList();
    return PageView(
      controller: _controller,
      children: pages,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: _isParsing ? _progressIndicator : _book,
      ),
    );
  }
}
