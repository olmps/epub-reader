import 'dart:async';
import 'dart:ui' as ui;

import 'package:epub_parser/epub_parser.dart';
import 'package:epub_renderer/src/book_page.dart';
import 'package:epub_renderer/src/page_turn/page_turn.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'book_page.dart';
import 'page_turn/page_turn.dart';

@immutable
class EpubRenderer extends StatefulWidget {
  final String _filePath;
  final bool isAudioEnabled;
  final bool isAutoReadEnabled;

  const EpubRenderer(this._filePath, {this.isAudioEnabled = true, this.isAutoReadEnabled = true});

  @override
  _EpubRendererState createState() {
    return _EpubRendererState();
  }
}

class _EpubRendererState extends State<EpubRenderer> {
  Epub _epub;
  bool _isParsing = true;
  double _progress = 0;

  _EpubRendererState();

  @override
  void initState() {
    super.initState();
    // Timer(Duration(seconds: 3), () {
    //   setState(() {});
    // });

    _loadEpub();
  }

  Widget get _progressIndicator {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Loading ePub, please wait'),
          const SizedBox(height: 20),
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
    EpubParser.parse(widget._filePath, (progress) {
      setState(() {
        _progress = progress;
      });
    }, (epub) {
      setState(() {
        _isParsing = false;
        _epub = epub;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isParsing ? _progressIndicator : Renderer(_epub);
  }
}

/// Renderer

class _PageRenderer {
  final BookPage widget;
  final int idx;

  InAppWebViewController webviewController;
  CustomPaint widgetPrint;

  _PageRenderer(this.idx, this.widget);

  @override
  String toString() {
    return 'IDX: $idx - is showing print: ${widgetPrint != null}';
  }
}

class Renderer extends StatefulWidget {
  final Epub epub;

  Renderer(this.epub);

  @override
  State<StatefulWidget> createState() => _RendererState();
}

class _RendererState extends State<Renderer> with TickerProviderStateMixin {
  List<Chapter> get _chapters => widget.epub.chapters;

  int _currentChapterIndex = 0;
  bool get _isLastPage => (pages.length - 1) == _currentChapterIndex;
  bool get _isFirstPage => _currentChapterIndex == 0;

  final pages = <int, _PageRenderer>{};
  final pagesAnimationController = <int, AnimationController>{};

  _PageRenderer get _prev => _currentChapterIndex - 1 > 0 ? pages[_currentChapterIndex - 1] : null;
  _PageRenderer get _current => pages[_currentChapterIndex];
  _PageRenderer get _next => _currentChapterIndex + 1 < _chapters.length ? pages[_currentChapterIndex + 1] : null;

  bool get _isAcceptingGestures =>
      _current.webviewController != null &&
      _current.widgetPrint != null &&
      // TODO: still have to be able to call gestures in last (next) page.
      _next?.webviewController != null &&
      _next?.widgetPrint != null;

  bool _hasCompletedInit = false;

  @override
  void initState() {
    super.initState();

    for (var chapterIndex = 0; chapterIndex < _chapters.length; chapterIndex++) {
      _buildPageAt(chapterIndex);
    }
  }

  final double dragCutoffThreshold = 0.5;
  bool _isDraggingCurrentPage;

  @override
  Widget build(BuildContext context) {
    // WidgetsBinding.instance.addPostFrameCallback((_) {});

    // return ReproducibleBug();

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragCancel: () {
            print('Cancelled Drag');
            _isDraggingCurrentPage = null;
          },
          onHorizontalDragUpdate: (details) {
            _dragPage(details, constraints);
          },
          onHorizontalDragEnd: (details) {
            print('Finished Drag');
            _onDragFinish();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_next != null) _next.widget,
              if (_current.widgetPrint != null && _isDraggingCurrentPage != null) _current.widgetPrint,
              // Visibility(
              //   key: _current.widgetPrint.key,
              //   visible: _isDraggingForward != null,
              //   maintainState: true,
              //   maintainInteractivity: true,
              //   maintainSize: true,
              //   maintainAnimation: true,
              //   maintainSemantics: true,
              //   child: _current.widgetPrint,
              // ),
              Offstage(
                key: _current.widget.key,
                offstage: _isDraggingCurrentPage != null,
                child: _current.widget,
              ),
              // Visibility(
              //   key: _current.widget.key,
              //   visible: _isDraggingForward == null,
              //   maintainState: true,
              //   maintainInteractivity: true,
              //   maintainSize: true,
              //   maintainAnimation: true,
              //   maintainSemantics: true,
              //   child: _current.widget,
              // ),
              if (_prev != null) _prev.widgetPrint ?? _prev.widget,
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                key: ValueKey('CurrentPageTextWidget'),
                child: Text(
                  'Page $_currentChapterIndex / ${_chapters.length - 1}',
                  textAlign: TextAlign.center,
                ),
              ),
              if (!_hasCompletedInit)
                Positioned(
                  key: ValueKey('FirstInitLoading'),
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.black38,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _dragPage(DragUpdateDetails details, BoxConstraints dimens) {
    final _ratio = details.delta.dx / dimens.maxWidth;

    if (_isDraggingCurrentPage == null) {
      setState(() {
        _isDraggingCurrentPage = details.delta.dx < 0;
      });
    } else {
      _isDraggingCurrentPage = details.delta.dx < 0;
    }

    // If the delta is negative, it's the current page that is being dragged
    // Otherwise, we assume that it's the previous page (delta positive)
    // _isDraggingCurrentPage ??= details.delta.dx < 0;

    print('Dragging ratio: $_ratio');

    if (_isDraggingCurrentPage || _isFirstPage) {
      pagesAnimationController[_currentChapterIndex].value += _ratio;
    } else {
      pagesAnimationController[_currentChapterIndex - 1].value += _ratio;
    }
  }

  Future _onDragFinish() async {
    if (_isDraggingCurrentPage) {
      if (!_isLastPage && pagesAnimationController[_currentChapterIndex].value <= dragCutoffThreshold) {
        await pagesAnimationController[_currentChapterIndex].reverse();
        setState(() {
          _currentChapterIndex++;
        });
      } else {
        await pagesAnimationController[_currentChapterIndex].forward();
      }
    } else {
      if (!_isFirstPage && pagesAnimationController[_currentChapterIndex - 1].value >= dragCutoffThreshold) {
        await pagesAnimationController[_currentChapterIndex - 1].forward();
        setState(() {
          _currentChapterIndex--;
        });
      } else {
        if (!_isFirstPage) {
          await pagesAnimationController[_currentChapterIndex - 1].reverse();
        }
      }
    }

    setState(() {
      _isDraggingCurrentPage = null;
    });
  }

  void _buildPageAt(int index) {
    Future<void> whenVisible(InAppWebViewController controller, int index) async {
      print('Completed IAWVC Loading in IDX $index');

      pages[index].webviewController = controller;
      final currentPageImage = await _takeScreenshotAt(index);

      setState(() {
        pages[index].widgetPrint = CustomPaint(
          key: ValueKey('BookPagePrint_$index'), // TODO: Can we assume a key for this?
          painter: PageTurnEffect(
            amount: pagesAnimationController[index],
            image: currentPageImage,
          ),
          size: Size.infinite,
        );

        _hasCompletedInit = true;
      });
    }

    final pageWidget = BookPage(
      ValueKey('BookPage_$index'),
      _chapters[index],
      widget.epub.metadata.highlightClassName,
      false,
      () {},
      (controller) {
        whenVisible(controller, index);
      },
    );

    pages[index] = _PageRenderer(index, pageWidget);
    pagesAnimationController[index] = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 450),
    );
  }

  Future<ui.Image> _takeScreenshotAt(int index) async {
    final currentPagePrint = await pages[index].webviewController.takeScreenshot();

    final completer = Completer<ImageInfo>();
    MemoryImage(currentPagePrint).resolve(createLocalImageConfiguration(context)).addListener(
      ImageStreamListener(
        (info, _) {
          completer.complete(info);
        },
      ),
    );

    final imageInfo = await completer.future;

    return imageInfo.image;
  }
}

/////

class ReproducibleBug extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BugState();
}

class _BugState extends State<ReproducibleBug> {
  List<Widget> pages;

  bool isAnimating = false;
  int currentIndex = 0;

  @override
  void initState() {
    pages = List.generate(
      10,
      (index) => Container(
        key: ValueKey(index),
        color: Color.fromRGBO(200, 0 + index * 40, 0 + index * 50, 1),
      ),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragCancel: () {
        print('Cancelled Drag');
        setState(() {
          isAnimating = false;
        });
      },
      onHorizontalDragUpdate: (details) {
        print('Updated Drag');
        setState(() {
          isAnimating = true;
        });
      },
      onHorizontalDragEnd: (details) {
        print('Finished Drag');
        setState(() {
          isAnimating = false;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (currentIndex > 0) pages[currentIndex + 1],
          if (isAnimating) Text('Is ANIMATING!') else pages[currentIndex],
          // if (currentIndex + 1 < pages.length) pages[currentIndex + 1],
        ],
      ),
    );
  }
}
