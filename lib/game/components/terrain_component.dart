/// ============================================================
/// Terrain Component — Renders and manages a single map tile.
/// ============================================================
/// Supports partial destruction for brick tiles (4 quadrants).
/// Pre-allocates all Paint objects in onLoad to avoid GC.
/// Forest tiles render at priority 10 (above tanks).
/// ============================================================


import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../battle_city_game.dart';
import '../../model/terrain_model.dart';

class TerrainComponent extends PositionComponent {
  final TerrainTile tile;
  final int gridX;
  final int gridY;

  // ── Pre-allocated Paint objects ──
  late final Paint _brickPaint;
  late final Paint _brickDarkPaint;
  late final Paint _brickMortarPaint;
  late final Paint _steelPaint;
  late final Paint _steelHighlightPaint;
  late final Paint _waterPaint;
  late final Paint _waterDarkPaint;
  late final Paint _icePaint;
  late final Paint _iceHighlightPaint;
  late final Paint _forestPaint;
  late final Paint _forestDarkPaint;

  // ── Water animation ──
  double _waterAnimTimer = 0;
  int _waterFrame = 0;


  TerrainComponent({
    required this.tile,
    required this.gridX,
    required this.gridY,
  }) : super(
    position: Vector2(gridX * kCellSize, gridY * kCellSize),
    size: Vector2.all(kCellSize),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ── Pre-allocate all paints ──
    _brickPaint = Paint()..color = const Color(0xFFC84C0C);
    _brickDarkPaint = Paint()..color = const Color(0xFF8C2800);
    _brickMortarPaint = Paint()..color = const Color(0xFF6C6C6C);
    _steelPaint = Paint()..color = const Color(0xFFB0B0B0);
    _steelHighlightPaint = Paint()..color = const Color(0xFFE0E0E0);
    _waterPaint = Paint()..color = const Color(0xFF2038EC);
    _waterDarkPaint = Paint()..color = const Color(0xFF0000A8);
    _icePaint = Paint()..color = const Color(0xFFA8D8FF);
    _iceHighlightPaint = Paint()..color = const Color(0xFFDDEEFF);
    _forestPaint = Paint()..color = const Color(0xFF006800);
    _forestDarkPaint = Paint()..color = const Color(0xFF004400);

    // Add collision hitbox for blocking tiles.
    if (tile.blocksTanks && tile.type != TileType.base) {
      add(RectangleHitbox()..collisionType = CollisionType.passive);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Animate water.
    if (tile.type == TileType.water) {
      _waterAnimTimer += dt;
      if (_waterAnimTimer > 0.5) {
        _waterAnimTimer = 0;
        _waterFrame = (_waterFrame + 1) % 2;
      }
    }
  }

  /// Mark tile as needing re-render (after brick destruction).
  void markDirty() {
    // Flame will re-render on next frame automatically.
  }

  @override
  void render(Canvas canvas) {
    if (tile.type == TileType.empty) return;

    switch (tile.type) {
      case TileType.brick:
        _renderBrick(canvas);
        break;
      case TileType.steel:
        _renderSteel(canvas);
        break;
      case TileType.water:
        _renderWater(canvas);
        break;
      case TileType.ice:
        _renderIce(canvas);
        break;
      case TileType.forest:
        _renderForest(canvas);
        break;
      default:
        break;
    }

  }

  void _renderBrick(Canvas canvas) {
    final half = kCellSize / 2;

    // Each quadrant is a half-cell.
    final quadrants = [
      Rect.fromLTWH(0, 0, half, half),        // topLeft
      Rect.fromLTWH(half, 0, half, half),      // topRight
      Rect.fromLTWH(0, half, half, half),      // bottomLeft
      Rect.fromLTWH(half, half, half, half),   // bottomRight
    ];

    for (int i = 0; i < 4; i++) {
      if (!tile.quadrants[i]) continue;

      final q = quadrants[i];

      // Mortar background.
      canvas.drawRect(q, _brickMortarPaint);

      // Brick pattern (alternating rows of bricks).
      final brickW = half / 3;
      final brickH = half / 3;

      for (int row = 0; row < 3; row++) {
        final offset = (row % 2 == 0) ? 0.0 : brickW / 2;
        for (double x = -brickW / 2 + offset;
            x < half;
            x += brickW) {
          final bx = q.left + x;
          final by = q.top + row * brickH;
          if (bx >= q.left && bx + brickW - 1 <= q.right) {
            canvas.drawRect(
              Rect.fromLTWH(bx + 0.5, by + 0.5, brickW - 1, brickH - 1),
              (row + x.toInt()) % 2 == 0 ? _brickPaint : _brickDarkPaint,
            );
          }
        }
      }
    }
  }

  void _renderSteel(Canvas canvas) {
    final s = kCellSize;

    // Steel base.
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), _steelPaint);

    // Rivet pattern.
    final rivetSize = 4.0;
    for (double x = 4; x < s; x += 12) {
      for (double y = 4; y < s; y += 12) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, rivetSize, rivetSize),
          _steelHighlightPaint,
        );
      }
    }

    // Edge highlight.
    canvas.drawRect(Rect.fromLTWH(0, 0, s, 2), _steelHighlightPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, 2, s), _steelHighlightPaint);
  }

  void _renderWater(Canvas canvas) {
    final s = kCellSize;

    // Base water color.
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), _waterPaint);

    // Animated wave pattern.
    final waveOffset = _waterFrame * 4.0;
    for (double y = waveOffset; y < s; y += 8) {
      for (double x = 0; x < s; x += 6) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, 4, 2),
          _waterDarkPaint,
        );
      }
    }
  }

  void _renderIce(Canvas canvas) {
    final s = kCellSize;

    // Ice base.
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), _icePaint);

    // Highlight streaks.
    for (double x = 4; x < s; x += 10) {
      canvas.drawRect(
        Rect.fromLTWH(x, 2, 3, s - 4),
        _iceHighlightPaint,
      );
    }
  }

  void _renderForest(Canvas canvas) {
    final s = kCellSize;

    // Forest canopy (rendered above tanks due to priority 10).
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), _forestDarkPaint);

    // Tree crown circles.
    for (double x = 6; x < s; x += 12) {
      for (double y = 6; y < s; y += 12) {
        canvas.drawCircle(
          Offset(x, y),
          7,
          _forestPaint,
        );
      }
    }

    // Leaf detail.
    final leafPaint = Paint()..color = const Color(0xFF00A800);
    for (double x = 3; x < s; x += 8) {
      for (double y = 3; y < s; y += 8) {
        canvas.drawCircle(Offset(x, y), 3, leafPaint);
      }
    }
  }
}
