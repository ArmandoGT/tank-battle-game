/// ============================================================
/// Enemy Controller — Enemy spawning and type selection.
/// ============================================================
/// Determines which type of enemy spawns based on stage number
/// and spawn index. Higher stages introduce tougher enemies.
/// ============================================================

import 'package:get/get.dart';
import '../model/tank_model.dart';

class EnemyController extends GetxController {
  /// Determine the enemy type for a given spawn index and stage.
  /// Matches NES Battle City enemy composition by stage difficulty.
  TankType getNextEnemyType(int spawnIndex, int stage) {
    // Enemy distribution scales with stage number.
    // Early stages: mostly basic. Later stages: more armor/power.
    final difficulty = (stage / 35.0).clamp(0.0, 1.0);

    // Distribution thresholds.
    final armorThreshold = 0.1 + difficulty * 0.25;
    final powerThreshold = armorThreshold + 0.15 + difficulty * 0.15;
    final fastThreshold = powerThreshold + 0.2;

    // Use spawn index modulo to create varied mix.
    final roll = (spawnIndex * 7 + stage * 13) % 100 / 100.0;

    if (roll < armorThreshold) return TankType.armorEnemy;
    if (roll < powerThreshold) return TankType.powerEnemy;
    if (roll < fastThreshold) return TankType.fastEnemy;
    return TankType.basicEnemy;
  }
}
