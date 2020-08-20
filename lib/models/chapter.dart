import 'package:epub_reader/models/smil.dart';

class Chapter {

  String chapterContent;
  String contentFilePath;
  Smil smil;

  Chapter(this.chapterContent, this.contentFilePath, this.smil);
}