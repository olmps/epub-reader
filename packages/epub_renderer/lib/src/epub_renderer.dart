import 'package:epub_parser/epub_parser.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'book_page.dart';

class EpubRenderer extends StatefulWidget {
  final String _filePath;
  final bool isAudioEnabled;
  final bool isAutoReadEnabled;

  EpubRenderer(this._filePath, {this.isAudioEnabled = true, this.isAutoReadEnabled = true});

  @override
  _EpubRendererState createState() {
    return _EpubRendererState();
  }
}

class _EpubRendererState extends State<EpubRenderer> {
  Epub _epub;
  bool _isParsing = false;
  bool _finishedParsing = false;
  double _progress = 0;
  final _controller = PageController();

  _EpubRendererState();

  Widget get _progressIndicator {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Loading ePub, please wait'),
          SizedBox(height: 20),
          LinearProgressIndicator(
            backgroundColor: Colors.grey,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 40,
            value: _progress / 100,
          ),
        ],
      ),
    );
  }

  _loadEpub() {
    setState(() {
      _isParsing = true;
    });

    EpubParser.parse(widget._filePath, (progress) {
      setState(() {
        _progress = progress;
      });
    }, (epub) {
      setState(() {
        _finishedParsing = true;
        _epub = epub;
      });
    });
  }

  Widget get _book {
    final pages = _epub.chapters.map((chapter) {
      return BookPage(
        chapter,
        _epub.metadata.highlightClassName,
        widget.isAudioEnabled,
        () {
          if (widget.isAutoReadEnabled) {
            _controller.nextPage(
              duration: Duration(milliseconds: 400), // Default transition duration
              curve: Curves.easeInOut,
            ); // Default curve
          }
        },
      );
    }).toList();

    return PageView(
      children: pages,
      controller: _controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isParsing) _loadEpub();

    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: _finishedParsing ? _book : _progressIndicator,
      ),
    );
  }
}
