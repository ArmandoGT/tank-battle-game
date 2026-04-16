/// ============================================================
/// Game State Model — Overall game session data.
/// ============================================================
/// Managed by the GameController (GetX). Only low-frequency
/// meta-state lives here — not per-frame physics data.
/// ============================================================

/// The phase of the current game session.
enum GamePhase {
  mainMenu,
  stageIntro,
  playing,
  paused,
  gameOver,
  victory,
}

class GameState {
  /// Current stage number (1-35).
  int currentStage;

  /// Whether this is a two-player game.
  bool isTwoPlayer;

  /// Score per player.
  int scorePlayer1;
  int scorePlayer2;

  /// Lives remaining per player.
  int livesPlayer1;
  int livesPlayer2;

  /// Total enemies remaining for this stage (out of 20).
  int enemiesRemaining;

  /// Current game phase.
  GamePhase phase;

  /// Whether all enemies on this stage have been destroyed.
  bool get stageCleared => enemiesRemaining <= 0;

  /// Whether the base has been destroyed.
  bool baseDestroyed;

  /// Whether enemies are currently frozen (clock power-up).
  bool enemiesFrozen;
  double freezeTimer;

  /// Whether base is fortified with steel (shovel power-up).
  bool baseFortified;
  double fortifyTimer;

  GameState({
    this.currentStage = 1,
    this.isTwoPlayer = false,
    this.scorePlayer1 = 0,
    this.scorePlayer2 = 0,
    this.livesPlayer1 = 3,
    this.livesPlayer2 = 3,
    this.enemiesRemaining = 20,
    this.phase = GamePhase.mainMenu,
    this.baseDestroyed = false,
    this.enemiesFrozen = false,
    this.freezeTimer = 0,
    this.baseFortified = false,
    this.fortifyTimer = 0,
  });

  /// Reset state for a new stage.
  void nextStage() {
    currentStage++;
    enemiesRemaining = 20;
    baseDestroyed = false;
    enemiesFrozen = false;
    freezeTimer = 0;
    baseFortified = false;
    fortifyTimer = 0;
  }

  /// Reset entire game state for new game.
  void reset({bool twoPlayer = false}) {
    currentStage = 1;
    isTwoPlayer = twoPlayer;
    scorePlayer1 = 0;
    scorePlayer2 = 0;
    livesPlayer1 = 3;
    livesPlayer2 = 3;
    enemiesRemaining = 20;
    phase = GamePhase.mainMenu;
    baseDestroyed = false;
    enemiesFrozen = false;
    freezeTimer = 0;
    baseFortified = false;
    fortifyTimer = 0;
  }
}
