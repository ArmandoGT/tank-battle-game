/// ============================================================
/// Power-Up Component — Collectible items spawned by flashing enemies.
/// ============================================================

import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../battle_city_game.dart';
import '../../model/power_up_model.dart';
import 'tank_component.dart';

class PowerUpComponent extends PositionComponent
    with CollisionCallbacks {

  PowerUpModel? model;
  bool isActive = false;

  // ── Pre-allocated rendering ──
  late final Paint _bgPaint;
  late final Paint _iconPaint;
  late final Paint _flashPaint;

  double _flashTimer = 0;
  bool _visible = true;

  PowerUpComponent() : super(
    size: Vector2.all(kCellSize),
    anchor: Anchor.topLeft,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _bgPaint = Paint()..color = const Color(0xFF000000);
    _iconPaint = Paint()..color = const Color(0xFFFF0000);
    _flashPaint = Paint()..color = const Color(0xFFFFFFFF);

    add(RectangleHitbox()..collisionType = CollisionType.inactive);
  }

  void activate(PowerUpModel powerUp) {
    model = powerUp;
    isActive = true;
    position.setValues(powerUp.x, powerUp.y);
    children.whereType<RectangleHitbox>().firstOrNull
        ?.collisionType = CollisionType.passive;
  }

  void deactivate() {
    isActive = false;
    model = null;
    position.setValues(-100, -100);
    children.whereType<RectangleHitbox>().firstOrNull
        ?.collisionType = CollisionType.inactive;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive || model == null) return;

    model!.lifetime -= dt;
    if (model!.lifetime <= 0) {
      deactivate();
      return;
    }

    // Flashing effect.
    _flashTimer += dt;
    _visible = (_flashTimer * 4).floor() % 2 == 0;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (!isActive || model == null) return;

    if (other is TankComponent && other.model.isPlayer) {
      _applyPowerUp(other);
      deactivate();
    }
  }

  void _applyPowerUp(TankComponent tank) {
    if (model == null) return;
    final game = findParent<World>()?.parent;
    if (game is! BattleCityGame) return;

    switch (model!.type) {
      case PowerUpType.star:
        if (tank.model.tier < 3) tank.model.tier++;
        break;
      case PowerUpType.helmet:
        tank.model.isShielded = true;
        tank.model.shieldTimer = 10.0;
        break;
      case PowerUpType.clock:
        game.freezeAllEnemies();
        break;
      case PowerUpType.shovel:
        game.activateFortification();
        break;
      case PowerUpType.grenade:
        game.destroyAllEnemies();
        break;
      case PowerUpType.extraLife:
        game.gameController.addLife(tank.model.type);
        break;
    }

    game.audioService.playPowerUp();
  }

  @override
  void render(Canvas canvas) {
    if (!isActive || !_visible || model == null) return;

    final s = kCellSize;

    // Background.
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), _bgPaint);

    // Icon varies by type.
    _iconPaint.color = _getColor();

    switch (model!.type) {
      case PowerUpType.star:
        _drawStar(canvas, s);
        break;
      case PowerUpType.helmet:
        _drawHelmet(canvas, s);
        break;
      case PowerUpType.clock:
        _drawClock(canvas, s);
        break;
      case PowerUpType.shovel:
        _drawShovel(canvas, s);
        break;
      case PowerUpType.grenade:
        _drawGrenade(canvas, s);
        break;
      case PowerUpType.extraLife:
        _drawTank(canvas, s);
        break;
    }
  }

  Color _getColor() {
    switch (model!.type) {
      case PowerUpType.star:      return const Color(0xFFFFFF00);
      case PowerUpType.helmet:    return const Color(0xFF00FF00);
      case PowerUpType.clock:     return const Color(0xFF00FFFF);
      case PowerUpType.shovel:    return const Color(0xFFFF8800);
      case PowerUpType.grenade:   return const Color(0xFFFF0000);
      case PowerUpType.extraLife: return const Color(0xFFFFFF00);
    }
  }

  void _drawStar(Canvas canvas, double s) {
    _iconPaint.color = const Color(0xFFFFFF00);
    final c = s / 2;
    canvas.drawCircle(Offset(c, c), 12, _iconPaint);
    canvas.drawRect(Rect.fromLTWH(c - 2, 4, 4, s - 8), _iconPaint);
    canvas.drawRect(Rect.fromLTWH(4, c - 2, s - 8, 4), _iconPaint);
  }

  void _drawHelmet(Canvas canvas, double s) {
    _iconPaint.color = const Color(0xFF00FF00);
    canvas.drawCircle(Offset(s / 2, s / 2 - 2), 14, _iconPaint);
    canvas.drawRect(Rect.fromLTWH(6, s / 2 + 4, s - 12, 10), _iconPaint);
  }

  void _drawClock(Canvas canvas, double s) {
    _iconPaint.color = const Color(0xFF00FFFF);
    canvas.drawCircle(Offset(s / 2, s / 2), 14, _iconPaint);
    final handPaint = Paint()..color = const Color(0xFF000000)..strokeWidth = 2;
    canvas.drawLine(Offset(s / 2, s / 2), Offset(s / 2, s / 2 - 10), handPaint);
    canvas.drawLine(Offset(s / 2, s / 2), Offset(s / 2 + 6, s / 2), handPaint);
  }

  void _drawShovel(Canvas canvas, double s) {
    _iconPaint.color = const Color(0xFFFF8800);
    canvas.drawRect(Rect.fromLTWH(s / 2 - 2, 4, 4, s - 8), _iconPaint);
    canvas.drawRect(Rect.fromLTWH(s / 2 - 8, s - 16, 16, 12), _iconPaint);
  }

  void _drawGrenade(Canvas canvas, double s) {
    _iconPaint.color = const Color(0xFFFF0000);
    canvas.drawCircle(Offset(s / 2, s / 2 + 4), 12, _iconPaint);
    canvas.drawRect(Rect.fromLTWH(s / 2 - 3, 4, 6, 12), _iconPaint);
  }

  void _drawTank(Canvas canvas, double s) {
    _iconPaint.color = const Color(0xFFFFFF00);
    canvas.drawRect(Rect.fromLTWH(8, 10, s - 16, s - 20), _iconPaint);
    canvas.drawRect(Rect.fromLTWH(s / 2 - 2, 4, 4, 12), _iconPaint);
  }
}
