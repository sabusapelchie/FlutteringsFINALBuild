import 'package:audioplayers/audioplayers.dart';

//Eto naman is for background music, ung naririnig niyo sa game. Configurable sa supabase, so ayun, if gusto niyo mag set ng music, mag set lang kayo
//ng url sa music_asset.
class BackgroundMusicService {
  static final BackgroundMusicService _instance =
      BackgroundMusicService._internal();

  factory BackgroundMusicService() => _instance;
  BackgroundMusicService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  String? _currentAsset;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await playDefault();
  }

  Future<void> playDefault() async {
    await _playAsset('audio/flutters.mp3');
  }

  Future<void> playLevelMusic(String assetPath) async {
    await _playAsset(assetPath);
  }

  Future<void> _playAsset(String assetPath) async {
    if (_currentAsset == assetPath) return;

    _currentAsset = assetPath;
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.6);
    await _player.play(AssetSource(assetPath));
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }
}
