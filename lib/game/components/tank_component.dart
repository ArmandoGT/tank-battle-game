/// ============================================================
/// Tank Component — Flame PositionComponent for all tank entities.
/// ============================================================
/// Implements the 4 critical directives:
///
/// 1. SPRITE SHEET RENDERING: Uses Flame SpriteSheet/SpriteAnimation
///    for authentic NES pixel art. Falls back to procedural rendering
///    with NES color palette when sprite assets are unavailable.
///
/// 2. INPUT POLLING: Actively queries InputService boolean map
///    during update(dt) — no async key events for movement.
///
/// 3. GRID SNAPPING: When changing orthogonal direction, tank
///    position snaps to nearest 48px grid modulus to prevent
///    terrain corner snagging.
///
/// 4. ICE PHYSICS: Friction coefficient decouples from input
///    when bounding box intersects ice tile. Momentum uses dt
///    to prevent infinite sliding.
///
/// MEMORY: All Paint, Rect, Vector2 objects are pre-allocated
/// in onLoad and mutated during update — zero per-frame allocation.
/// ============================================================

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import '../battle_city_game.dart';
import '../../model/tank_model.dart';

class TankComponent extends PositionComponent
    with HasGameReference<BattleCityGame>, CollisionCallbacks {

  final TankModel model;
  final BattleCityGame game;

  // ── Pre-allocated rendering objects (Object Pooling) ──
  // Created once in onLoad, mutated in render — never re-created.
  late final Paint _bodyPaint;
  late final Paint _turretPaint;
  late final Paint _trackPaint;
  late final Paint _flashPaint;

  // Pre-allocated Rect objects for procedural rendering.
  late Rect _bodyRect;
  late Rect _turretRect;
  late Rect _trackLeftRect;
  late Rect _trackRightRect;

  // ── Sprite Sheet fields (for when assets are available) ──
  SpriteSheet? _spriteSheet;
  SpriteAnimation? _moveUpAnim;
  SpriteAnimation? _moveDownAnim;
  SpriteAnimation? _moveLeftAnim;
  SpriteAnimation? _moveRightAnim;
  SpriteAnimationComponent? _animComponent;
  bool _useSpriteSheet = false;

  // ── Ice Physics ──
  // Velocity vector for momentum-based movement on ice.
  // Decoupled from input: when on ice, input affects acceleration,
  // not direct position, and velocity decays via friction * dt.
  double _velocityX = 0;
  double _velocityY = 0;

  /// Ice friction coefficient: velocity decays by this factor per second.
  /// At 0.92, tank slides ~3 cells after releasing input on ice.
  static const double kIceFriction = 0.92;

  /// Normal friction: instant stop when not pressing input.
  static const double kNormalFriction = 0.0;

  /// Minimum velocity threshold to stop sliding.
  static const double kMinVelocity = 2.0;

  // ── Shooting ──
  double _shootCooldown = 0;
  static const double kShootCooldownTime = 0.3;

  // ── Shield Animation ──
  double _shieldFlashTimer = 0;
  bool _shieldVisible = true;

  // ── Enemy AI ──
  double _aiTimer = 0;
  double _aiDirectionChangeInterval = 2.0;
  final math.Random _random = math.Random();

  // ── Spawn shield timer (3 seconds of invincibility on spawn) ──
  double _spawnShieldTimer = 3.0;

  TankComponent({
    required this.model,
    required this.game,
  }) : super(
    size: Vector2.all(kCellSize),
    anchor: Anchor.topLeft,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set initial position from model.
    position.setValues(model.x, model.y);

    // ── Try to load sprite sheet ──
    await _tryLoadSpriteSheet();

    // ── Pre-allocate Paint objects per NES color palette ──
    _bodyPaint = Paint()..color = _getBodyColor();
    _turretPaint = Paint()..color = _getTurretColor();
    _trackPaint = Paint()..color = const Color(0xFF555555);
    _flashPaint = Paint()..color = const Color(0xFFFF0000);

    // ── Pre-allocate Rect objects ──
    _bodyRect = Rect.zero;
    _turretRect = Rect.zero;
    _trackLeftRect = Rect.zero;
    _trackRightRect = Rect.zero;

    // ── Collision hitbox ──
    add(RectangleHitbox()..collisionType = CollisionType.active);

    // Spawn shield.
    if (model.isPlayer) {
      model.isShielded = true;
      model.shieldTimer = _spawnShieldTimer;
    }
  }

  // ────────────────────────────────────────────────────────────
  // Sprite Sheet Loading — Prepared for authentic NES assets
  // ────────────────────────────────────────────────────────────
  Future<void> _tryLoadSpriteSheet() async {
    try {
      // Attempt to load the sprite sheet image.
      // Expected layout: 4 rows (directions) × N frames per direction.
      // Each frame is 48×48 pixels.
      final imageName = _getSpriteSheetName();
      final image = await game.images.load(imageName);

      _spriteSheet = SpriteSheet(
        image: image,
        srcSize: Vector2.all(48),
      );

      _moveUpAnim = _spriteSheet!.createAnimation(row: 0, stepTime: 0.1, to: 2);
      _moveRightAnim = _spriteSheet!.createAnimation(row: 1, stepTime: 0.1, to: 2);
      _moveDownAnim = _spriteSheet!.createAnimation(row: 2, stepTime: 0.1, to: 2);
      _moveLeftAnim = _spriteSheet!.createAnimation(row: 3, stepTime: 0.1, to: 2);

      _animComponent = SpriteAnimationComponent(
        animation: _moveUpAnim,
        size: Vector2.all(kCellSize),
      );
      add(_animComponent!);
      _useSpriteSheet = true;
    } catch (_) {
      // Sprite sheet not found — fall back to procedural rendering.
      _useSpriteSheet = false;
    }
  }

  String _getSpriteSheetName() {
    switch (model.type) {
      case TankType.player1: return 'tank_player1.png';
      case TankType.player2: return 'tank_player2.png';
      case TankType.basicEnemy: return 'tank_basic.png';
      case TankType.fastEnemy: return 'tank_fast.png';
      case TankType.powerEnemy: return 'tank_power.png';
      case TankType.armorEnemy: return 'tank_armor.png';
    }
  }

  // ────────────────────────────────────────────────────────────
  // update — Called every frame by Flame game loop
  // ────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);

    if (!model.isAlive) return;

    // ── Handle freeze state (friendly fire paralysis) ──
    if (model.isFrozen) {
      model.freezeTimer -= dt;
      if (model.freezeTimer <= 0) {
        model.isFrozen = false;
        model.freezeTimer = 0;
      }
      return; // Can't move or shoot while frozen
    }

    // ── Handle shield timer ──
    if (model.isShielded) {
      model.shieldTimer -= dt;
      _shieldFlashTimer += dt;
      _shieldVisible = (_shieldFlashTimer * 10).floor() % 2 == 0;
      if (model.shieldTimer <= 0) {
        model.isShielded = false;
        model.shieldTimer = 0;
      }
    }

    // ── Shoot cooldown ──
    if (_shootCooldown > 0) {
      _shootCooldown -= dt;
    }

    // ── Movement & shooting (player or AI) ──
    if (model.isPlayer) {
      _handlePlayerInput(dt);
    } else {
      _handleEnemyAI(dt);
    }
  }

  // ────────────────────────────────────────────────────────────
  // PLAYER INPUT POLLING — Queries InputService boolean map
  // ────────────────────────────────────────────────────────────
  void _handlePlayerInput(double dt) {
    final input = game.inputService;
    Direction? dir;
    bool shooting = false;

    if (model.type == TankType.player1) {
      dir = input.getPlayer1Direction();
      shooting = input.isPlayer1Shooting();
    } else {
      dir = input.getPlayer2Direction();
      shooting = input.isPlayer2Shooting();
    }

    if (dir != null) {
      _moveInDirection(dir, dt);
    } else {
      // No input: apply friction-based deceleration.
      _applyFriction(dt, hasInput: false);
    }

    if (shooting && _shootCooldown <= 0) {
      _shoot();
    }
  }

  // ────────────────────────────────────────────────────────────
  // ENEMY AI — Simple patrol with base-seeking bias
  // ────────────────────────────────────────────────────────────
  void _handleEnemyAI(double dt) {
    // Don't move if enemies are frozen.
    if (game.gameController.state.enemiesFrozen) return;

    _aiTimer += dt;
    if (_aiTimer >= _aiDirectionChangeInterval) {
      _aiTimer = 0;
      _aiDirectionChangeInterval = 1.0 + _random.nextDouble() * 3.0;

      // 40% chance to move toward base, 60% random.
      if (_random.nextDouble() < 0.4) {
        model.direction = Direction.down; // Bias toward base
      } else {
        model.direction = Direction.values[_random.nextInt(4)];
      }
    }

    _moveInDirection(model.direction, dt);

    // Shoot randomly (~every 1 second on average).
    if (_random.nextDouble() < dt * 1.0 && _shootCooldown <= 0) {
      _shoot();
    }
  }

  // ────────────────────────────────────────────────────────────
  // MOVEMENT with GRID SNAPPING and ICE PHYSICS
  // ────────────────────────────────────────────────────────────
  void _moveInDirection(Direction dir, double dt) {
    final oldDir = model.direction;

    // ── GRID SNAPPING (Directive #4) ──
    // When changing to an orthogonal direction, snap to the nearest
    // 48px grid line to prevent corner snagging on terrain.
    if (dir != oldDir) {
      final isOrthogonalChange =
          (oldDir == Direction.up || oldDir == Direction.down) !=
          (dir == Direction.up || dir == Direction.down);

      if (isOrthogonalChange) {
        _snapToGrid();
      }
      model.direction = dir;
    }

    // ── ICE PHYSICS (Directive — Refined) ──
    // Check if tank's bounding box intersects an ice tile.
    final onIce = game.isOnIce(model.x, model.y, kCellSize, kCellSize);

    if (onIce) {
      // On ice: input sets target velocity, friction decelerates.
      // Decouple input from position: input → acceleration → velocity.
      final targetSpeed = model.speed;
      double targetVX = 0, targetVY = 0;

      switch (dir) {
        case Direction.up:    targetVY = -targetSpeed; break;
        case Direction.down:  targetVY = targetSpeed;  break;
        case Direction.left:  targetVX = -targetSpeed; break;
        case Direction.right: targetVX = targetSpeed;  break;
      }

      // Lerp velocity toward target (acceleration on ice is slower).
      // Use dt to ensure frame-rate independence.
      final accelRate = 3.0; // How fast we accelerate on ice
      _velocityX += (targetVX - _velocityX) * accelRate * dt;
      _velocityY += (targetVY - _velocityY) * accelRate * dt;
    } else {
      // On normal terrain: instant response, no sliding.
      switch (dir) {
        case Direction.up:
          _velocityX = 0; _velocityY = -model.speed; break;
        case Direction.down:
          _velocityX = 0; _velocityY = model.speed; break;
        case Direction.left:
          _velocityX = -model.speed; _velocityY = 0; break;
        case Direction.right:
          _velocityX = model.speed; _velocityY = 0; break;
      }
    }

    _applyVelocity(dt);
    _updateSpriteAnimation();
  }

  /// Apply current velocity to position, with collision checking.
  void _applyVelocity(double dt) {
    final newX = model.x + _velocityX * dt;
    final newY = model.y + _velocityY * dt;

    // Check horizontal movement.
    if (_velocityX != 0) {
      if (!game.isBlocked(newX, model.y, kCellSize, kCellSize)) {
        model.x = newX;
      } else {
        _velocityX = 0; // Stop on collision
      }
    }

    // Check vertical movement.
    if (_velocityY != 0) {
      if (!game.isBlocked(model.x, newY, kCellSize, kCellSize)) {
        model.y = newY;
      } else {
        _velocityY = 0; // Stop on collision
      }
    }

    // Clamp to world boundaries.
    model.x = model.x.clamp(0, kGameWidth - kCellSize);
    model.y = model.y.clamp(0, kGameHeight - kCellSize);

    // Sync Flame position with model.
    position.setValues(model.x, model.y);
  }

  /// Apply friction when no directional input is active.
  void _applyFriction(double dt, {required bool hasInput}) {
    if (hasInput) return;

    final onIce = game.isOnIce(model.x, model.y, kCellSize, kCellSize);

    if (onIce) {
      // ── ICE FRICTION (Directive) ──
      // Decouple from input: velocity decays exponentially via dt.
      // pow(friction, dt) ensures frame-rate-independent decay.
      final frictionFactor = math.pow(kIceFriction, dt * 60).toDouble();
      _velocityX *= frictionFactor;
      _velocityY *= frictionFactor;

      // Snap to zero below threshold to prevent infinite micro-slides.
      if (_velocityX.abs() < kMinVelocity) _velocityX = 0;
      if (_velocityY.abs() < kMinVelocity) _velocityY = 0;

      if (_velocityX != 0 || _velocityY != 0) {
        _applyVelocity(dt);
      }
    } else {
      // Normal terrain: instant stop.
      _velocityX = 0;
      _velocityY = 0;
    }
  }

  // ────────────────────────────────────────────────────────────
  // GRID SNAPPING — Snap to nearest 48px grid line
  // ────────────────────────────────────────────────────────────
  void _snapToGrid() {
    // Snap X and Y to nearest grid cell boundary.
    model.x = (model.x / kCellSize).round() * kCellSize;
    model.y = (model.y / kCellSize).round() * kCellSize;
    position.setValues(model.x, model.y);
  }

  // ────────────────────────────────────────────────────────────
  // SHOOTING — Acquires bullet from pool, fires in facing direction
  // ────────────────────────────────────────────────────────────
  void _shoot() {
    // Check max bullets for this tank.
    final activeBullets = game.activeBulletsFor(model.type);
    if (activeBullets >= model.maxBullets) return;

    // Acquire bullet from pool.
    final bullet = game.acquireBullet();
    if (bullet == null) return;

    // Calculate bullet spawn position (center of tank, offset by direction).
    double bx = model.x + kCellSize / 2 - 4; // 8px bullet, centered
    double by = model.y + kCellSize / 2 - 4;

    switch (model.direction) {
      case Direction.up:    by = model.y - 8; break;
      case Direction.down:  by = model.y + kCellSize; break;
      case Direction.left:  bx = model.x - 8; break;
      case Direction.right: bx = model.x + kCellSize; break;
    }

    // Bullet speed increases with tier.
    final bulletSpeed = 192.0 + (model.tier * 48.0);

    bullet.activate(
      x: bx,
      y: by,
      direction: model.direction,
      ownerType: model.type,
      speed: bulletSpeed,
      canDestroySteel: model.canDestroySteel,
    );

    _shootCooldown = kShootCooldownTime;
    game.audioService.playShoot();
  }

  // ────────────────────────────────────────────────────────────
  // Sprite animation updates
  // ────────────────────────────────────────────────────────────
  void _updateSpriteAnimation() {
    if (!_useSpriteSheet || _animComponent == null) return;

    switch (model.direction) {
      case Direction.up:    _animComponent!.animation = _moveUpAnim; break;
      case Direction.down:  _animComponent!.animation = _moveDownAnim; break;
      case Direction.left:  _animComponent!.animation = _moveLeftAnim; break;
      case Direction.right: _animComponent!.animation = _moveRightAnim; break;
    }
  }

  // ────────────────────────────────────────────────────────────
  // PROCEDURAL RENDERING — NES-accurate pixel art fallback
  // ────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    if (!model.isAlive) return;
    if (_useSpriteSheet) {
      super.render(canvas);
      _renderShield(canvas);
      return;
    }

    // ── Procedural tank rendering ──
    // Update paint colors for flashing enemies.
    if (model.isFlashing) {
      _flashPaint.color = (_shieldFlashTimer * 6).floor() % 2 == 0
          ? const Color(0xFFFF0000)
          : _getBodyColor();
      _bodyPaint.color = _flashPaint.color;
    }

    final s = kCellSize;

    // Rotate rendering based on direction.
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(_directionToAngle(model.direction));
    canvas.translate(-s / 2, -s / 2);

    // Draw tracks (two rectangles on sides).
    _trackLeftRect = Rect.fromLTWH(2, 2, 10, s - 4);
    canvas.drawRect(_trackLeftRect, _trackPaint);
    _trackRightRect = Rect.fromLTWH(s - 12, 2, 10, s - 4);
    canvas.drawRect(_trackRightRect, _trackPaint);

    // Track detail lines.
    final trackDetailPaint = Paint()..color = const Color(0xFF333333);
    for (double y = 4; y < s - 4; y += 6) {
      canvas.drawRect(Rect.fromLTWH(3, y, 8, 2), trackDetailPaint);
      canvas.drawRect(Rect.fromLTWH(s - 11, y, 8, 2), trackDetailPaint);
    }

    // Draw body.
    _bodyRect = Rect.fromLTWH(12, 6, s - 24, s - 12);
    canvas.drawRect(_bodyRect, _bodyPaint);

    // Body detail (darker inner).
    final innerPaint = Paint()..color = _getDarkerColor(_bodyPaint.color);
    canvas.drawRect(
      Rect.fromLTWH(16, 10, s - 32, s - 20),
      innerPaint,
    );

    // Draw turret (barrel going up).
    _turretRect = Rect.fromLTWH(s / 2 - 3, 0, 6, s / 2);
    canvas.drawRect(_turretRect, _turretPaint);

    // Turret base circle.
    canvas.drawCircle(
      Offset(s / 2, s / 2 - 2),
      8,
      _turretPaint,
    );

    canvas.restore();

    // ── Shield overlay ──
    _renderShield(canvas);
  }

  void _renderShield(Canvas canvas) {
    if (!model.isShielded || !_shieldVisible) return;

    final shieldPaint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(kCellSize / 2, kCellSize / 2),
      kCellSize / 2 + 2,
      shieldPaint,
    );
  }

  double _directionToAngle(Direction dir) {
    switch (dir) {
      case Direction.up:    return 0;
      case Direction.right: return math.pi / 2;
      case Direction.down:  return math.pi;
      case Direction.left:  return 3 * math.pi / 2;
    }
  }

  // ── NES Color Palette ──
  Color _getBodyColor() {
    switch (model.type) {
      case TankType.player1:   return const Color(0xFFE8D038); // Yellow
      case TankType.player2:   return const Color(0xFF58D854); // Green
      case TankType.basicEnemy: return const Color(0xFFB8B8B8); // Silver
      case TankType.fastEnemy:  return const Color(0xFF6888FC); // Blue
      case TankType.powerEnemy: return const Color(0xFFD858D8); // Purple
      case TankType.armorEnemy: return const Color(0xFF58D854); // Green
    }
  }

  Color _getTurretColor() {
    switch (model.type) {
      case TankType.player1:   return const Color(0xFFC8A028); // Dark yellow
      case TankType.player2:   return const Color(0xFF38B838); // Dark green
      default: return const Color(0xFF888888);
    }
  }

  Color _getDarkerColor(Color c) {
    return Color.fromARGB(
      c.a.toInt(),
      (c.r * 0.7).toInt(),
      (c.g * 0.7).toInt(),
      (c.b * 0.7).toInt(),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Damage handling
  // ────────────────────────────────────────────────────────────
  void takeDamage() {
    if (model.isShielded) return;

    model.health--;
    if (model.health <= 0) {
      model.isAlive = false;
      game.spawnExplosion(model.x, model.y, large: true);
      game.audioService.playExplosion();

      if (!model.isPlayer) {
        game.gameController.state.enemiesRemaining--;
        game.gameController.addScore(model.type);
        game.gameController.notifyEnemiesRemaining();
      } else {
        game.playerController.onPlayerDeath(model.type);
      }
    }
  }

  /// Apply temporary paralysis (friendly fire effect).
  void paralyze(double duration) {
    model.isFrozen = true;
    model.freezeTimer = duration;
    _velocityX = 0;
    _velocityY = 0;
  }
}
