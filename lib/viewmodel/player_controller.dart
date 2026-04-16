/// ============================================================
/// Player Controller — Manages player-specific state.
/// ============================================================
/// Tracks respawn logic, tier persistence across respawns,
/// and communicates deaths to GameController.
/// ============================================================

import 'package:get/get.dart';
import '../model/tank_model.dart';
import 'game_controller.dart';

class PlayerController extends GetxController {
  late final GameController _gameController;

  /// Player 1 tier persists across respawns in the same stage.
  int p1Tier = 0;
  int p2Tier = 0;

  @override
  void onInit() {
    super.onInit();
    _gameController = Get.find<GameController>();
  }

  /// Called when a player tank is destroyed.
  void onPlayerDeath(TankType playerType) {
    if (playerType == TankType.player1) {
      _gameController.state.livesPlayer1--;
      p1Tier = 0; // Reset tier on death
    } else {
      _gameController.state.livesPlayer2--;
      p2Tier = 0;
    }
    _gameController.notifyPlayerDeath(playerType);
  }

  /// Called when player collects a star power-up.
  void upgradeTier(TankType playerType) {
    if (playerType == TankType.player1) {
      if (p1Tier < 3) p1Tier++;
    } else {
      if (p2Tier < 3) p2Tier++;
    }
  }

  /// Get the current tier for a player type.
  int getTier(TankType playerType) {
    return playerType == TankType.player1 ? p1Tier : p2Tier;
  }

  /// Reset player state for new game.
  void reset() {
    p1Tier = 0;
    p2Tier = 0;
  }
}
