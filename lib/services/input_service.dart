/// ============================================================
/// Input Service — Keyboard input polling for two players.
/// ============================================================
/// Uses a boolean map strategy: components poll key states during
/// update(dt) instead of relying on async key-down events.
/// This ensures frame-perfect input handling at 60 FPS.
/// ============================================================

import 'package:flutter/services.dart';
import '../model/tank_model.dart';

class InputService {
  /// Private map of currently-pressed keys.
  /// Components poll this map during update() for smooth movement.
  final Map<LogicalKeyboardKey, bool> _pressedKeys = {};

  /// Call from FlameGame.onKeyEvent to update key states.
  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _pressedKeys[event.logicalKey] = true;
    } else if (event is KeyUpEvent) {
      _pressedKeys[event.logicalKey] = false;
    }
  }

  /// Check if a specific key is currently held down.
  bool isKeyPressed(LogicalKeyboardKey key) {
    return _pressedKeys[key] ?? false;
  }

  // ── Player 1 Controls (WASD + Space) ──

  /// Returns the direction Player 1 is pressing, or null if no movement.
  Direction? getPlayer1Direction() {
    if (isKeyPressed(LogicalKeyboardKey.keyW)) return Direction.up;
    if (isKeyPressed(LogicalKeyboardKey.keyS)) return Direction.down;
    if (isKeyPressed(LogicalKeyboardKey.keyA)) return Direction.left;
    if (isKeyPressed(LogicalKeyboardKey.keyD)) return Direction.right;
    return null;
  }

  /// Whether Player 1 is pressing the shoot button.
  bool isPlayer1Shooting() =>
      isKeyPressed(LogicalKeyboardKey.space);

  // ── Player 2 Controls (Arrow Keys + Enter) ──

  /// Returns the direction Player 2 is pressing, or null if no movement.
  Direction? getPlayer2Direction() {
    if (isKeyPressed(LogicalKeyboardKey.arrowUp)) return Direction.up;
    if (isKeyPressed(LogicalKeyboardKey.arrowDown)) return Direction.down;
    if (isKeyPressed(LogicalKeyboardKey.arrowLeft)) return Direction.left;
    if (isKeyPressed(LogicalKeyboardKey.arrowRight)) return Direction.right;
    return null;
  }

  /// Whether Player 2 is pressing the shoot button.
  bool isPlayer2Shooting() =>
      isKeyPressed(LogicalKeyboardKey.enter);

  // ── General ──

  /// Whether the pause key is pressed.
  bool isPausePressed() =>
      isKeyPressed(LogicalKeyboardKey.escape);

  /// Reset all key states (e.g., on focus loss).
  void reset() {
    _pressedKeys.clear();
  }
}
