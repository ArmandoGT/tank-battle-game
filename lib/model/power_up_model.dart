/// ============================================================
/// Power-Up Model — Types and effects for collectible items.
/// ============================================================

/// The 6 NES-accurate power-up types.
enum PowerUpType {
  star,       // Upgrade tank tier (faster bullets, double shot, steel-break)
  helmet,     // Temporary invincibility shield
  clock,      // Freeze all enemies for ~10 seconds
  shovel,     // Fortify base with steel walls temporarily
  grenade,    // Destroy all on-screen enemies instantly
  extraLife,  // +1 life for the collecting player
}

class PowerUpModel {
  PowerUpType type;
  double x;
  double y;

  /// Whether this power-up is still on the map (not yet collected/expired).
  bool isActive;

  /// Time remaining before the power-up despawns (seconds).
  double lifetime;

  /// Flashing animation timer.
  double flashTimer;

  PowerUpModel({
    required this.type,
    required this.x,
    required this.y,
    this.isActive = true,
    this.lifetime = 15.0,
    this.flashTimer = 0,
  });
}
