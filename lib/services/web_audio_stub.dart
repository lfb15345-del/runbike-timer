/// ネイティブ版のスタブ（何もしない）
/// Web版では web_audio_web.dart が使われる
class WebAudioService {
  static void playTick() {}
  static void playWhistle() {}
  static void startMetronome(int bpm) {}
  static void stopMetronome() {}
  static void startUpbeat() {}
  static void stopUpbeat() {}
  static void stopAll() {}
  static void preloadSound(String filename) {}
  static Future<void> preloadAllSounds() async {}
  static void playSoundBuffer(String filename) {}
  static void stopSoundBuffer() {}
}
