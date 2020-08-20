library epub_reader;

import 'package:epub_reader/parser.dart';
import 'package:epub_reader/models/epub.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:epub_reader/book_page.dart';

class EpubReader extends StatefulWidget {
  final String _filePath;
  bool isAudioEnabled = true;
  bool isAutoReadEnabled = true;

  EpubReader(this._filePath, {this.isAudioEnabled, this.isAutoReadEnabled});

  @override
  _EpubReaderState createState() {
    return _EpubReaderState();
  }
}

class _EpubReaderState extends State<EpubReader> {
  
  Epub _epub;
  bool _isParsing = false;
  bool _finishedParsing = false;
  double _progress;
  final _controller = PageController();

  _EpubReaderState();

  Widget get _progressIndicator {
    return LinearProgressIndicator(
      backgroundColor: Colors.grey,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
      value: _progress / 100,
    );
  }

  _loadEpub() {
      setState(() { _isParsing = true; });
      EpubParser.parse(widget._filePath, (progress) {
        setState(() { _progress = progress; });
      }, (epub) {
        setState(() {
          _finishedParsing = true;
          _epub = epub;
        });
      });
  }

  Widget get _book {
    final pages = _epub.chapters.map((chapter) {
      return BookPage(chapter, _epub.metadata.highlightClassName, widget.isAudioEnabled, () {
        if (widget.isAutoReadEnabled) {
          _controller.nextPage(duration: Duration(milliseconds: 400),  // Default transition duration
                               curve: Curves.easeInOut); // Default curve
        }
      });
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
      )
    );
  }
}