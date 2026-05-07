import 'package:audioplayers/audioplayers.dart';

/// Manages looping background music for the game.
/// Call [play] when entering gameplay and [pause] when leaving.
class MusicService {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  bool get isPlaying => _playing;

  Future<void> play() async {
    if (_playing) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/musica.mp3'));
      _playing = true;
    } catch (_) {
      // Music file may not exist yet — fail silently.
    }
  }

  Future<void> pause() async {
    if (!_playing) return;
    await _player.pause();
    _playing = false;
  }

  Future<void> disposeService() async {
    await _player.dispose();
  }
}
