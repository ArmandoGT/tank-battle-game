/// ============================================================
/// Explosion Component — Animated pixel explosion effect.
/// ============================================================
/// Pooled in BattleCityGame. Activated/deactivated, never created
/// or destroyed during gameplay to avoid GC pressure.
/// ============================================================

import 'dart:ui';
import 'package:flame/components.dart';
import '../battle_city_game.dart';

class ExplosionComponent extends PositionComponent {
  bool isActive = false;
  double _timer = 0;
  double _duration = 0.4;
  bool _isLarge = false;

  // Pre-allocated paints.
  late final Paint _outerPaint;
  late final Paint _midPaint;
  late final Paint _innerPaint;
  late final Paint _corePaint;

  ExplosionComponent() : super(
    size: Vector2.all(kCellSize),
    anchor: Anchor.topLeft,
    priority: 20, // Render above everything
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _outerPaint = Paint()..color = const Color(0xFFFF8800);
    _midPaint = Paint()..color = const Color(0xFFFF4400);
    _innerPaint = Paint()..color = const Color(0xFFFFFF00);
    _corePaint = Paint()..color = const Color(0xFFFFFFFF);
  }

  void activate(double x, double y, {bool large = false}) {
    isActive = true;
    _timer = 0;
    _isLarge = large;
    _duration = large ? 0.6 : 0.4;
    position.setValues(x, y);
  }

  void deactivate() {
    isActive = false;
    position.setValues(-200, -200);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive) return;

    _timer += dt;
    if (_timer >= _duration) {
      deactivate();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;

    // Animation progress (0 → 1).
    final progress = (_timer / _duration).clamp(0.0, 1.0);
    final center = kCellSize / 2;

    // Explosion expands then contracts.
    final scale = progress < 0.5
        ? progress * 2  // Expand
        : 2 - progress * 2; // Contract

    final baseRadius = _isLarge ? 28.0 : 20.0;
    final radius = baseRadius * scale;

    if (radius <= 0) return;

    // Outer glow (fading orange).
    _outerPaint.color = Color.fromARGB(
      ((1 - progress) * 200).toInt(),
      255, 136, 0,
    );
    canvas.drawCircle(Offset(center, center), radius, _outerPaint);

    // Mid layer (red).
    if (radius > 4) {
      _midPaint.color = Color.fromARGB(
        ((1 - progress) * 220).toInt(),
        255, 68, 0,
      );
      canvas.drawCircle(Offset(center, center), radius * 0.7, _midPaint);
    }

    // Inner (yellow).
    if (radius > 8) {
      _innerPaint.color = Color.fromARGB(
        ((1 - progress) * 240).toInt(),
        255, 255, 0,
      );
      canvas.drawCircle(Offset(center, center), radius * 0.4, _innerPaint);
    }

    // Core (white flash).
    if (progress < 0.3) {
      canvas.drawCircle(
        Offset(center, center),
        radius * 0.2,
        _corePaint,
      );
    }
  }
}
