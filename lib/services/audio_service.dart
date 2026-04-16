/// ============================================================
/// Audio Service — Stub for retro sound effects.
/// ============================================================
/// Placeholder methods for future SFX integration.
/// Replace stubs with flame_audio calls when assets are available.
/// ============================================================

class AudioService {
  bool isMuted = false;

  void playShoot() {
    if (isMuted) return;
    // TODO: FlameAudio.play('shoot.wav');
  }

  void playExplosion() {
    if (isMuted) return;
    // TODO: FlameAudio.play('explosion.wav');
  }

  void playPowerUp() {
    if (isMuted) return;
    // TODO: FlameAudio.play('powerup.wav');
  }

  void playGameOver() {
    if (isMuted) return;
    // TODO: FlameAudio.play('gameover.wav');
  }

  void playStageStart() {
    if (isMuted) return;
    // TODO: FlameAudio.play('stage_start.wav');
  }

  void playMove() {
    if (isMuted) return;
    // TODO: FlameAudio.play('move.wav');
  }

  void toggleMute() {
    isMuted = !isMuted;
  }
}
