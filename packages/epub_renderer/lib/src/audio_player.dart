import 'dart:async';

import 'package:just_audio/just_audio.dart' as JustAudio;

typedef OnAudioFinish = Function();

class AudioPlayer {
  String _filePath;
  int _beginMilliseconds;
  int _durationInMilliseconds;
  OnAudioFinish _onFinish;

  Timer _scheduledAudioPlay;

  JustAudio.AudioPlayer _player = JustAudio.AudioPlayer();

  AudioPlayer(this._filePath, this._beginMilliseconds, this._onFinish);

  void schedule() {
    _scheduledAudioPlay = Timer(
      Duration(milliseconds: _beginMilliseconds),
      () async {
        await _player.setFilePath(_filePath);
        await _player.seek(Duration(milliseconds: _beginMilliseconds));
        await _player.play();
        _onFinish();
      },
    );
  }

  Future<void> cancel() async {
    await _player.stop();
    _scheduledAudioPlay.cancel();
  }
}
