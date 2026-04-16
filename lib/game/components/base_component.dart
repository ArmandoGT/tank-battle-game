/// ============================================================
/// Base Component — The Eagle/Phoenix that must be protected.
/// ============================================================
/// Located at bottom-center of the map. If destroyed → Game Over.
/// ============================================================

import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../battle_city_game.dart';

class BaseComponent extends PositionComponent with CollisionCallbacks {
  final int gridX;
  final int gridY;
  bool isDestroyed = false;

  // Pre-allocated paints.
  late final Paint _basePaint;
  late final Paint _eaglePaint;
  late final Paint _eagleWingPaint;
  late final Paint _destroyedPaint;

  BaseComponent({
    required this.gridX,
    required this.gridY,
  }) : super(
    position: Vector2(gridX * kCellSize, gridY * kCellSize),
    size: Vector2.all(kCellSize),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _basePaint = Paint()..color = const Color(0xFF808080);
    _eaglePaint = Paint()..color = const Color(0xFFE8A000);
    _eagleWingPaint = Paint()..color = const Color(0xFFC87800);
    _destroyedPaint = Paint()..color = const Color(0xFF404040);

    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    final s = kCellSize;

    if (isDestroyed) {
      // Destroyed base — rubble.
      canvas.drawRect(Rect.fromLTWH(0, 0, s, s), _destroyedPaint);
      // X mark.
      final xPaint = Paint()
        ..color = const Color(0xFFFF0000)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(4, 4), Offset(s - 4, s - 4), xPaint);
      canvas.drawLine(Offset(s - 4, 4), Offset(4, s - 4), xPaint);
      return;
    }

    // ── Eagle/Phoenix rendering ──
    // Background.
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), _basePaint);

    // Eagle body.
    canvas.drawRect(
      Rect.fromLTWH(s / 2 - 8, 8, 16, 28),
      _eaglePaint,
    );

    // Wings.
    canvas.drawRect(Rect.fromLTWH(4, 14, 12, 16), _eagleWingPaint);
    canvas.drawRect(Rect.fromLTWH(s - 16, 14, 12, 16), _eagleWingPaint);

    // Head.
    canvas.drawCircle(Offset(s / 2, 10), 6, _eaglePaint);

    // Eye.
    canvas.drawCircle(
      Offset(s / 2, 9),
      2,
      Paint()..color = const Color(0xFF000000),
    );
  }
}
