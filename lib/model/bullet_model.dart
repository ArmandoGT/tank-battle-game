/// ============================================================
/// Bullet Model — Data representation for projectiles.
/// ============================================================

import 'tank_model.dart';

class BulletModel {
  /// The type of tank that fired this bullet.
  TankType ownerType;

  /// Direction the bullet travels.
  Direction direction;

  /// Position in game-world pixels.
  double x;
  double y;

  /// Speed in pixels/second. Higher-tier tanks shoot faster.
  double speed;

  /// Whether this bullet can destroy steel walls (owner tier >= 3).
  bool canDestroySteel;

  /// Whether this bullet is still active (not yet collided).
  bool isActive;

  BulletModel({
    required this.ownerType,
    required this.direction,
    required this.x,
    required this.y,
    this.speed = 192.0,
    this.canDestroySteel = false,
    this.isActive = true,
  });

  /// Whether this bullet was fired by a player.
  bool get isPlayerBullet =>
      ownerType == TankType.player1 || ownerType == TankType.player2;
}
