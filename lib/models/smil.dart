import 'package:epub_reader/models/xml_entity.dart';

class SmilEvent {

  String highlightedLabelId;

  String audioFilePath;
  String audioBeginTimestamp;
  String audioEndTimestamp;

  bool get hasAudio => audioFilePath != null;
  bool get hasTextHighlight => highlightedLabelId != null;

  SmilEvent([this.highlightedLabelId, this.audioFilePath, this.audioBeginTimestamp, this.audioEndTimestamp]);
}

class Smil {

  String _smilFilePath;
  XMLEntity _smilFile;

  String get _smilRootDirectory => _smilFilePath.substring(0, this._smilFilePath.lastIndexOf("/"));

  List<SmilEvent> events = [];

  Smil(this._smilFilePath);

  load() async {
    try {
      _smilFile = XMLEntity(this._smilFilePath);
      await _smilFile.load();
      await _loadContent();
    } catch (error) {
      throw error;
    }
  }

  _loadContent() async {
    final sequencies = _smilFile["body"].allOfTag("seq");
    
    for (var sequence in sequencies) {
      final sequencePairs = sequence.allOfTag("par");
      for (var pair in sequencePairs) {
        await _loadContentFromPair(pair);
      }
    }

    final rootPairs = _smilFile["body"].allOfTag("par");

    for (var pair in rootPairs) {
      await _loadContentFromPair(pair);
    }
  }

  _loadContentFromPair(XMLEntity pair) {
    final textSmilAttributes = pair["text"].attributes();
    final audioSmilAttributes = pair["audio"].attributes();

    var textIdentifier = textSmilAttributes["src"];
    textIdentifier = textIdentifier.substring(textIdentifier.lastIndexOf("#") + 1, textIdentifier.length);

    final audioAbsolutePath = "${this._smilRootDirectory}/${audioSmilAttributes["src"]}";
    final audioBeginTimestamp = audioSmilAttributes["clipBegin"];
    final audioEndTimestamp = audioSmilAttributes["clipEnd"];

    final smilEvent = SmilEvent(textIdentifier, audioAbsolutePath, audioBeginTimestamp, audioEndTimestamp);
    this.events.add(smilEvent);
  }
}