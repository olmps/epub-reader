import 'dart:io';
import 'dart:typed_data';

import 'package:epub_reader/models/chapter.dart';

class EpubMetadata {

  String _coverFilePath;
  Uint8List coverData;
  String highlightClassName;

  EpubMetadata(this._coverFilePath, this.highlightClassName);

  load() async {
    try {
      final coverFileReference = File(this._coverFilePath);
      this.coverData = coverFileReference.readAsBytesSync();
    } catch (error) {
      throw error;
    }
  }
}

class Epub {

  EpubMetadata metadata;
  List<Chapter> chapters = [];

  Epub(this.metadata, this.chapters);
}