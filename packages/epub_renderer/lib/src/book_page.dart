import 'dart:async';
import 'dart:convert';

import 'package:epub_parser/epub_parser.dart';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'audio_player.dart';
import 'utilities/time_formatter.dart';

typedef OnPageMediaFinish = void Function();

class BookPage extends StatefulWidget {
  final Chapter _chapter;
  final String _highlightClassName;
  final bool _shouldPlayAudio;
  final OnPageMediaFinish _onFinishMedia;
  final void Function(InAppWebViewController controller) _onFinishScripts;

  const BookPage(
    Key key,
    this._chapter,
    this._highlightClassName,
    this._shouldPlayAudio,
    this._onFinishMedia,
    this._onFinishScripts,
  ) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> with SingleTickerProviderStateMixin {
  WebViewController _controller;
  String _currentHighlightId;

  int _playingAudiosAmount = 0;
  List<AudioPlayer> _audioPlayers = [];
  List<Timer> _textHighlightOperations = [];

  _BookPageState();

  @override
  void dispose() {
    super.dispose();

    _audioPlayers.forEach((player) => player.cancel());
    _textHighlightOperations.forEach((operation) => operation.cancel());
  }

  /// Formats current page HTML content
  ///
  /// Injects CSS code to centralize the page content in the middle of the screen.
  /// Also injects the Javascript content to highlight and unhighlight labels
  String get _formattedChapterContent {
    const centeredContent = '''
      <style> body, html { height: 100%;
                           width: 100%;
                           display: flex;
                           justify-content: center;
                           align-items: center;
                           overflow: scroll;
                         }
      </style>
    ''';
    const highlightScript = '''
    <script>
      function highlight(elm, className) {
        if (typeof className !== 'undefined') {
          document.getElementById(elm).classList.add(className);
        } else {
          document.getElementById(elm).style.backgroundColor = 'yellow'; 
        } 
      }

      function undoHighlight(elm, className) { 
        if (typeof className !== 'undefined') { 
          document.getElementById(elm).classList.remove(className); 
        } else { 
          document.getElementById(elm).style.backgroundColor = ''; 
        } 
      }
    </script>
    ''';

    // TODO: is it only the first or all?
    return widget._chapter.chapterContent.replaceAllMapped(
      '<head>',
      (match) => '${match.group(0)} $centeredContent $highlightScript',
    );
  }

  /// Setup media events from the current ebook page
  ///
  /// Media events may be audio play and text highlights.
  /// These media events may happen sequentially and/or in
  /// parallel.
  void _setupMediaEvents() {
    if (widget._chapter.smil == null) return;

    for (var event in widget._chapter.smil.events) {
      if (event.hasAudio && widget._shouldPlayAudio) {
        // Increments the number of audios being played
        _playingAudiosAmount += 1;

        final filePath = event.audioFilePath;
        final audioBegin = parseISO8601ExtendedToMilliseconds(event.audioBeginTimestamp);
        final audioDuration = parseISO8601ExtendedToMilliseconds(event.audioEndTimestamp);

        final audioPlayer = AudioPlayer(filePath, audioBegin, audioDuration, () {
          _playingAudiosAmount -= 1;
          // If there are no audio media running, the page finished all it's media content
          if (_playingAudiosAmount == 0) widget._onFinishMedia();
        })
          // Schedule the media audio to be played on the correct time (according to `audioBegin` timestamp)
          ..schedule();

        _audioPlayers.add(audioPlayer);
      }

      if (event.hasTextHighlight) {
        // If there is no audio associated, the text is immediately highlighted
        final textHighlightBegin = event.hasAudio ? parseISO8601ExtendedToMilliseconds(event.audioBeginTimestamp) : 0;
        final textHighlightOperation = Timer(
          Duration(milliseconds: textHighlightBegin),
          () async => {_highlight(event.highlightedLabelId)},
        );

        _textHighlightOperations.add(textHighlightOperation);
      }
    }
  }

  /// Highlights the label with identifier `labelId`
  ///
  /// If another label is already highlighted, it removes the highlight from it.
  /// Use injected `highlight` function to add the highlight class name of `widget._highlightClassName`
  /// to highlight the desired label. The className is defined by the ebook style files.
  _highlight(String labelId) {
    if (_currentHighlightId != null) {
      _removeHighlight(_currentHighlightId);
    }

    _controller.evaluateJavascript("highlight('$labelId', '${widget._highlightClassName}')");
    _currentHighlightId = labelId;
  }

  /// Removes the highlight from the label with identifier `labelId`
  ///
  /// Similar to `_highlight` function, but instead adding, it removes the highlight from the label
  _removeHighlight(String labelId) {
    _controller.evaluateJavascript("undoHighlight('$labelId', '${widget._highlightClassName}')");
    _currentHighlightId = null;
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrl: Uri.dataFromString(
        _formattedChapterContent,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ).toString(),
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          debuggingEnabled: true,
        ),
      ),
      onLoadStop: (controller, url) {
        widget._onFinishScripts(controller);
      },
    );
  }
}
