import 'dart:async';

import 'package:just_audio/just_audio.dart' as JustAudio;

typedef OnAudioFinish = Function();

class AudioPlayer {

  String _filePath;
  int _beginMilliseconds;
  int _durationInMilliseconds;
  OnAudioFinish _onFinish;

  Timer _scheduledAudioPlay;
  Timer _scheduledAudioStop;

  JustAudio.AudioPlayer _player = JustAudio.AudioPlayer();

  AudioPlayer(this._filePath, this._beginMilliseconds, this._durationInMilliseconds, this._onFinish);

  schedule() {
    _scheduledAudioPlay = Timer(Duration(milliseconds: _beginMilliseconds), () async {
      await _player.setFilePath(_filePath);
      _player.seek(Duration(milliseconds: _beginMilliseconds));
      _player.play();
      _scheduleAudioFinish();
    });
  }

  _scheduleAudioFinish() {
    _scheduledAudioStop = Timer(
      Duration(milliseconds: _durationInMilliseconds), () {
        _player.stop();
        _onFinish();
      }
    );
  }

  cancel() {
    _player.stop();
    _scheduledAudioPlay.cancel();
    _scheduledAudioStop.cancel();
  }
}