import 'package:meta/meta.dart';

import 'xml_entity.dart';

class SmilEvent {
  String highlightedLabelId;

  String audioFilePath;
  String audioBeginTimestamp;
  String audioEndTimestamp;

  bool get hasAudio => audioFilePath != null;
  bool get hasTextHighlight => highlightedLabelId != null;

  SmilEvent([this.highlightedLabelId, this.audioFilePath, this.audioBeginTimestamp, this.audioEndTimestamp]);
}

@immutable
class Smil {
  final String path;
  final List<SmilEvent> events;
  final XMLEntity raw;

  const Smil._raw({@required this.path, @required this.events, @required this.raw});

  static Future<Smil> fromFilePath(String path) async {
    try {
      final xmlRepresentation = XMLEntity(path);
      await xmlRepresentation.load();

      final events = <SmilEvent>[];

      // Root pairs
      final rootPairs = xmlRepresentation['body'].allOfTag('par');
      events.addAll(rootPairs.map(_parsePairToEvent));

      // Sequence pairs
      final sequencePairs = xmlRepresentation['body'].allOfTag('seq');
      final flattenedSequencePairs = sequencePairs.map((e) => e.allOfTag('par')).expand((element) => element);
      events.addAll(flattenedSequencePairs.map(_parsePairToEvent));

      return Smil._raw(path: path, events: events, raw: xmlRepresentation);
    } catch (error) {
      // TODO: manage error
      rethrow;
    }
  }
}

SmilEvent _parsePairToEvent(XMLEntity pair) {
  final textSmilAttributes = pair['text'].attributes();
  final audioSmilAttributes = pair['audio'].attributes();

  var textSrc = textSmilAttributes['src'];
  textSrc = textSrc.substring(textSrc.lastIndexOf('#') + 1, textSrc.length);

  final rootDir = pair.path.substring(0, pair.path.lastIndexOf('/'));
  final audioSrc = audioSmilAttributes['src'];
  final audioAbsolutePath = '$rootDir/$audioSrc';

  final audioBeginTimestamp = audioSmilAttributes['clipBegin'];
  final audioEndTimestamp = audioSmilAttributes['clipEnd'];

  return SmilEvent(textSrc, audioAbsolutePath, audioBeginTimestamp, audioEndTimestamp);
}
