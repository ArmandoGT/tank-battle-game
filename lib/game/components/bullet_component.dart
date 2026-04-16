/// ============================================================
/// Bullet Component — Projectile with collision groups/masks.
/// ============================================================
/// Implements Flame's built-in HasCollisionDetection with
/// specific collision categorization:
///
///  • PlayerBullet vs EnemyBullet → CANCEL (both destroyed)
///  • PlayerBullet vs EnemyTank → DAMAGE enemy
///  • EnemyBullet vs PlayerTank → DAMAGE player
///  • PlayerBullet vs PlayerTank → PARALYZE (friendly fire)
///  • Bullet vs Terrain → DESTROY/BLOCK
///  • Bullet vs Bullet (same team) → IGNORE
///
/// MEMORY: Bullets are pooled in BattleCityGame. They are never
/// created/destroyed mid-game — only activated/deactivated.
/// All Paint/Vector2 objects are pre-allocated in onLoad.
/// ============================================================

import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../battle_city_game.dart';
import '../../model/tank_model.dart';
import 'tank_component.dart';

import 'base_component.dart';

/// Collision category constants for group-based filtering.
/// Using bit masks so the physics engine only tests relevant pairs.
abstract class CollisionCategory {
  static const int playerBullet = 1 << 0;  // 0b0001
  static const int enemyBullet  = 1 << 1;  // 0b0010
  static const int playerTank   = 1 << 2;  // 0b0100
  static const int enemyTank    = 1 << 3;  // 0b1000
  static const int terrain      = 1 << 4;  // 0b10000
}

class BulletComponent extends PositionComponent
    with CollisionCallbacks {

  // ── Bullet State ──
  bool isActive = false;
  Direction _direction = Direction.up;
  TankType _ownerType = TankType.player1;
  double _speed = 192.0;
  bool _canDestroySteel = false;

  /// The collision category of this bullet (used for group filtering).
  // ignore: unused_field
  int _category = CollisionCategory.playerBullet;

  /// The collision mask: which categories this bullet checks against.
  // ignore: unused_field
  int _mask = 0;

  // ── Pre-allocated rendering objects ──
  late final Paint _bulletPaint;
  late final Paint _glowPaint;
  late Rect _bulletRect;

  // ── Hitbox ──
  RectangleHitbox? _hitbox;

  /// Expose owner type for pool counting.
  TankType get ownerType => _ownerType;

  BulletComponent() : super(
    size: Vector2(8, 8),
    anchor: Anchor.topLeft,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Pre-allocate paints (mutated, never recreated).
    _bulletPaint = Paint()..color = const Color(0xFFFFFFFF);
    _glowPaint = Paint()..color = const Color(0x44FFFF00);
    _bulletRect = Rect.zero;

    // Create hitbox (stays on component, toggled via collisionType).
    _hitbox = RectangleHitbox()
      ..collisionType = CollisionType.inactive;
    add(_hitbox!);
  }

  // ────────────────────────────────────────────────────────────
  // Pool Lifecycle — Activate/Deactivate without alloc/dealloc
  // ────────────────────────────────────────────────────────────

  /// Activate this bullet from the pool.
  void activate({
    required double x,
    required double y,
    required Direction direction,
    required TankType ownerType,
    double speed = 192.0,
    bool canDestroySteel = false,
  }) {
    isActive = true;
    _direction = direction;
    _ownerType = ownerType;
    _speed = speed;
    _canDestroySteel = canDestroySteel;

    // Set position (mutate existing Vector2).
    position.setValues(x, y);

    // ── Configure collision groups/masks ──
    final isPlayerBullet = ownerType == TankType.player1 ||
                           ownerType == TankType.player2;

    if (isPlayerBullet) {
      _category = CollisionCategory.playerBullet;
      // Player bullets collide with: enemy tanks, enemy bullets, terrain
      // Player bullets also detect player tanks (friendly fire → paralyze)
      _mask = CollisionCategory.enemyTank |
              CollisionCategory.enemyBullet |
              CollisionCategory.terrain |
              CollisionCategory.playerTank;
      _bulletPaint.color = const Color(0xFFFFFF88); // Yellow tint
    } else {
      _category = CollisionCategory.enemyBullet;
      // Enemy bullets collide with: player tanks, player bullets, terrain
      _mask = CollisionCategory.playerTank |
              CollisionCategory.playerBullet |
              CollisionCategory.terrain;
      _bulletPaint.color = const Color(0xFFFFFFFF); // White
    }

    // Enable collision detection.
    _hitbox?.collisionType = CollisionType.active;
  }

  /// Deactivate this bullet back to the pool.
  void deactivate() {
    isActive = false;
    position.setValues(-100, -100); // Off-screen
    _hitbox?.collisionType = CollisionType.inactive;
  }

  // ────────────────────────────────────────────────────────────
  // update — Move bullet in its direction, check bounds/terrain
  // ────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive) return;

    // Move in direction.
    switch (_direction) {
      case Direction.up:
        position.y -= _speed * dt;
        break;
      case Direction.down:
        position.y += _speed * dt;
        break;
      case Direction.left:
        position.x -= _speed * dt;
        break;
      case Direction.right:
        position.x += _speed * dt;
        break;
    }

    // ── Boundary check ──
    if (position.x < -8 || position.x > kGameWidth + 8 ||
        position.y < -8 || position.y > kGameHeight + 8) {
      deactivate();
      return;
    }

    // ── Terrain collision (grid-based, O(1) per bullet) ──
    _checkTerrainCollision();
  }

  void _checkTerrainCollision() {
    // Get the game reference.
    final game = findParent<World>()?.parent;
    if (game == null || game is! BattleCityGame) return;

    // Check center point of bullet against terrain grid.
    final cx = position.x + 4;
    final cy = position.y + 4;

    final hit = game.destroyTerrainAt(
      cx, cy, _direction,
      canDestroySteel: _canDestroySteel,
    );

    if (hit) {
      game.spawnExplosion(position.x - 8, position.y - 8);
      deactivate();
    }
  }

  // ────────────────────────────────────────────────────────────
  // COLLISION CALLBACKS — Groups/masks for efficient filtering
  // ────────────────────────────────────────────────────────────

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (!isActive) return;

    // ── Bullet vs Bullet (projectile cancellation) ──
    if (other is BulletComponent && other.isActive) {
      final otherIsPlayer = other._ownerType == TankType.player1 ||
                            other._ownerType == TankType.player2;
      final thisIsPlayer = _ownerType == TankType.player1 ||
                           _ownerType == TankType.player2;

      // Only cancel if from different teams.
      if (thisIsPlayer != otherIsPlayer) {
        other.deactivate();
        deactivate();
        return;
      }
      // Same team bullets pass through each other.
      return;
    }

    // ── Bullet vs Tank ──
    if (other is TankComponent) {
      final targetIsPlayer = other.model.isPlayer;
      final bulletIsPlayer = _ownerType == TankType.player1 ||
                             _ownerType == TankType.player2;

      if (bulletIsPlayer && !targetIsPlayer) {
        // Player bullet hits enemy → damage.
        other.takeDamage();
        _spawnHitExplosion();
        deactivate();
      } else if (!bulletIsPlayer && targetIsPlayer) {
        // Enemy bullet hits player → damage.
        other.takeDamage();
        _spawnHitExplosion();
        deactivate();
      } else if (bulletIsPlayer && targetIsPlayer) {
        // ── FRIENDLY FIRE → Temporary paralysis, no damage ──
        if (_ownerType != other.model.type) {
          other.paralyze(1.0); // 1 second of paralysis
          deactivate();
        }
      }
      // Enemy bullet hitting enemy → ignore.
    }

    // ── Bullet vs Base ──
    if (other is BaseComponent) {
      _spawnHitExplosion();
      deactivate();
      // Base destruction is handled by terrain collision.
    }
  }

  void _spawnHitExplosion() {
    final game = findParent<World>()?.parent;
    if (game is BattleCityGame) {
      game.spawnExplosion(position.x - 8, position.y - 8);
      game.audioService.playExplosion();
    }
  }

  // ────────────────────────────────────────────────────────────
  // Rendering — Small white/yellow projectile with glow
  // ────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    if (!isActive) return;

    // Glow effect.
    canvas.drawCircle(
      const Offset(4, 4),
      6,
      _glowPaint,
    );

    // Bullet body.
    _bulletRect = const Rect.fromLTWH(1, 1, 6, 6);
    canvas.drawRect(_bulletRect, _bulletPaint);

    // Bright center pixel.
    canvas.drawRect(
      const Rect.fromLTWH(2, 2, 4, 4),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }
}
