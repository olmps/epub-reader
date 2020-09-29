import 'package:flutter/material.dart';

enum ReaderEvent { didLoad, didChangePage, didFinishPageMedia }

typedef OnReaderEvent = Function(ReaderEvent event, dynamic data);

abstract class Reader {
  final bool isAudioEnabled;
  final double minReadTime;
  final OnReaderEvent onEvent;

  const Reader({@required this.isAudioEnabled, @required this.minReadTime, @required this.onEvent});
}
