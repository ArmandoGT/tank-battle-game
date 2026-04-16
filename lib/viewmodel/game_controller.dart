/// ============================================================
/// Game Controller — Master GetX controller for game meta-state.
/// ============================================================
/// ARCHITECTURAL RULE: This controller manages LOW-FREQUENCY state
/// only (score, lives, stage transitions, game phase). It NEVER
/// touches per-frame physics data. Flame components read from
/// state directly; UI overlays observe Rx variables via Obx().
/// ============================================================

import 'package:get/get.dart';
import '../model/game_state.dart';
import '../model/tank_model.dart';

class GameController extends GetxController {
  /// The raw game state — mutated by Flame game loop.
  final GameState state = GameState();

  // ── Rx variables for UI observation (low-frequency updates) ──
  // These are only updated on discrete events (score change, death, etc.)
  // NEVER updated at 60 FPS to prevent widget tree rebuilds.

  final RxInt rxScoreP1 = 0.obs;
  final RxInt rxScoreP2 = 0.obs;
  final RxInt rxLivesP1 = 3.obs;
  final RxInt rxLivesP2 = 3.obs;
  final RxInt rxEnemiesRemaining = 20.obs;
  final RxInt rxCurrentStage = 1.obs;
  final Rx<GamePhase> rxPhase = GamePhase.mainMenu.obs;
  final RxBool rxIsTwoPlayer = false.obs;

  /// Start a new game.
  void startGame({bool twoPlayer = false}) {
    state.reset(twoPlayer: twoPlayer);
    state.phase = GamePhase.stageIntro;
    rxIsTwoPlayer.value = twoPlayer;
    _syncRxFromState();
    rxPhase.value = GamePhase.stageIntro;
  }

  /// Transition from stage intro to playing.
  void beginPlaying() {
    state.phase = GamePhase.playing;
    rxPhase.value = GamePhase.playing;
  }

  /// Trigger game over.
  void triggerGameOver() {
    if (state.phase == GamePhase.gameOver) return;
    state.phase = GamePhase.gameOver;
    rxPhase.value = GamePhase.gameOver;
  }

  /// Trigger stage completion.
  void triggerStageComplete() {
    if (state.phase != GamePhase.playing) return;
    state.phase = GamePhase.stageIntro;
    state.nextStage();
    _syncRxFromState();
    rxPhase.value = GamePhase.stageIntro;
  }

  /// Add score for destroying an enemy.
  void addScore(TankType enemyType) {
    final points = _scoreForEnemy(enemyType);
    // For simplicity, add to P1 score (could track who killed it).
    state.scorePlayer1 += points;
    rxScoreP1.value = state.scorePlayer1;
  }

  /// Add extra life.
  void addLife(TankType playerType) {
    if (playerType == TankType.player1) {
      state.livesPlayer1++;
      rxLivesP1.value = state.livesPlayer1;
    } else if (playerType == TankType.player2) {
      state.livesPlayer2++;
      rxLivesP2.value = state.livesPlayer2;
    }
  }

  /// Notify UI of enemies remaining change.
  void notifyEnemiesRemaining() {
    rxEnemiesRemaining.value = state.enemiesRemaining;
  }

  /// Notify UI after player death.
  void notifyPlayerDeath(TankType playerType) {
    if (playerType == TankType.player1) {
      rxLivesP1.value = state.livesPlayer1;
    } else {
      rxLivesP2.value = state.livesPlayer2;
    }
  }

  /// Toggle pause.
  void togglePause() {
    if (state.phase == GamePhase.playing) {
      state.phase = GamePhase.paused;
      rxPhase.value = GamePhase.paused;
    } else if (state.phase == GamePhase.paused) {
      state.phase = GamePhase.playing;
      rxPhase.value = GamePhase.playing;
    }
  }

  /// Return to main menu.
  void returnToMenu() {
    state.reset();
    _syncRxFromState();
    rxPhase.value = GamePhase.mainMenu;
  }

  int _scoreForEnemy(TankType type) {
    switch (type) {
      case TankType.basicEnemy: return 100;
      case TankType.fastEnemy: return 200;
      case TankType.powerEnemy: return 300;
      case TankType.armorEnemy: return 400;
      default: return 0;
    }
  }

  void _syncRxFromState() {
    rxScoreP1.value = state.scorePlayer1;
    rxScoreP2.value = state.scorePlayer2;
    rxLivesP1.value = state.livesPlayer1;
    rxLivesP2.value = state.livesPlayer2;
    rxEnemiesRemaining.value = state.enemiesRemaining;
    rxCurrentStage.value = state.currentStage;
  }
}
