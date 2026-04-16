/// ============================================================
/// Tank Model — Data representation for all tank entities.
/// ============================================================
/// Defines tank types, directions, and the mutable data model
/// used by both Flame components and GetX controllers.
/// ============================================================

/// The four cardinal directions a tank can face.
enum Direction { up, down, left, right }

/// All tank types in Battle City.
/// Player tanks and 4 NES-accurate enemy variants.
enum TankType {
  player1,
  player2,
  basicEnemy,   // Slow, 1 hit to destroy
  fastEnemy,    // Fast movement, 1 hit
  powerEnemy,   // Fast bullets, 1 hit
  armorEnemy,   // 4 hits to destroy
}

/// Mutable data model for a single tank.
/// Flame components read/write this; GetX controllers observe meta-state.
class TankModel {
  TankType type;
  Direction direction;
  double x;
  double y;

  /// Star tier (0-3). Affects bullet speed, count, and steel-breaking.
  /// - Tier 0: Normal bullet
  /// - Tier 1: Faster bullets
  /// - Tier 2: Two bullets on screen
  /// - Tier 3: Bullets destroy steel walls
  int tier;

  /// Base speed in pixels/second (varies by tank type).
  double speed;

  /// Number of hits remaining before destruction.
  int health;

  /// Whether this tank currently has a shield (invulnerable).
  bool isShielded;

  /// Shield remaining duration in seconds.
  double shieldTimer;

  /// Whether this tank is alive and active.
  bool isAlive;

  /// Whether this tank is temporarily frozen (friendly fire paralysis).
  bool isFrozen;

  /// Freeze remaining duration in seconds.
  double freezeTimer;

  /// Whether this is a flashing enemy (drops power-up on death).
  bool isFlashing;

  TankModel({
    required this.type,
    this.direction = Direction.up,
    this.x = 0,
    this.y = 0,
    this.tier = 0,
    this.speed = 96.0,
    this.health = 1,
    this.isShielded = false,
    this.shieldTimer = 0,
    this.isAlive = true,
    this.isFrozen = false,
    this.freezeTimer = 0,
    this.isFlashing = false,
  });

  /// Whether this tank belongs to a player (not an enemy).
  bool get isPlayer =>
      type == TankType.player1 || type == TankType.player2;

  /// Maximum bullets this tank can have on screen simultaneously.
  int get maxBullets => tier >= 2 ? 2 : 1;

  /// Whether bullets from this tank can destroy steel walls.
  bool get canDestroySteel => tier >= 3;

  /// Factory for creating enemy tanks with correct stats.
  factory TankModel.enemy(TankType type, {bool flashing = false}) {
    switch (type) {
      case TankType.basicEnemy:
        return TankModel(
          type: type,
          speed: 64.0,
          health: 1,
          isFlashing: flashing,
        );
      case TankType.fastEnemy:
        return TankModel(
          type: type,
          speed: 128.0,
          health: 1,
          isFlashing: flashing,
        );
      case TankType.powerEnemy:
        return TankModel(
          type: type,
          speed: 96.0,
          health: 1,
          tier: 1,
          isFlashing: flashing,
        );
      case TankType.armorEnemy:
        return TankModel(
          type: type,
          speed: 80.0,
          health: 4,
          isFlashing: flashing,
        );
      default:
        return TankModel(type: type, isFlashing: flashing);
    }
  }

  /// Factory for creating player tanks with default stats.
  factory TankModel.player(TankType type) {
    return TankModel(
      type: type,
      speed: 96.0,
      health: 1,
      tier: 0,
    );
  }
}
