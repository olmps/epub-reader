import 'dart:io';

import 'package:epub_renderer/epub_renderer.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(App());
}

class App extends StatefulWidget {
  @override
  AppState createState() {
    return AppState();
  }
}

class AppState extends State<App> {
  bool _isLoadingEbook = false;
  bool _isEbookLoaded = false;
  String _bookPath = "";

  _loadBook() async {
    setState(() {
      _isLoadingEbook = true;
    });
    final ebookBytes = await rootBundle.load('assets/elefante.epub');
    final tempPath = (await getTemporaryDirectory()).path;
    File epubFile = File("$tempPath/ebook.epub");
    epubFile.writeAsBytesSync(ebookBytes.buffer.asUint8List(ebookBytes.offsetInBytes, ebookBytes.lengthInBytes));
    setState(() {
      _bookPath = "$tempPath/ebook.epub";
      _isEbookLoaded = true;
    });
  }

  void onEvent(ReaderEvent event, dynamic data) {
    print('called event $event with data $data');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoadingEbook) {
      _loadBook();
    }

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: _isEbookLoaded
            ? EpubRenderer(
                epubFilePath: _bookPath,
                epubUrl: 'https://prod-us.elefanteletrado.com.br/cdn/Content/cdn/books/barata_v9_20200403105808.epub',
                apiKey: '4odruGhEJ8-m6aJtLbTvZEH8e0lcIJk-GpzO7jxe3Dk',
                isAudioEnabled: true,
                minReadTime: 1,
                onEvent: onEvent,
              )
            : Container(),
      ),
    );
  }
}
