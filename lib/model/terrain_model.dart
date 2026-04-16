/// ============================================================
/// Terrain Model — Tile types and grid data structures.
/// ============================================================
/// The Battle City map is a 13×13 grid of tiles.
/// Brick tiles support partial (quadrant) destruction.
/// ============================================================

/// All tile types in the game map.
enum TileType {
  empty,    // Passable, nothing here
  brick,    // Destructible wall (4 quadrants)
  steel,    // Indestructible (unless tier-3 bullet)
  water,    // Impassable to tanks, passable to bullets
  ice,      // Passable with reduced friction (slippery)
  forest,   // Passable, renders above tanks (camouflage)
  base,     // The eagle/phoenix — game over if destroyed
}

/// Represents a single tile on the 13×13 game grid.
/// Brick tiles have 4 sub-quadrants that can be individually destroyed:
///   [topLeft] [topRight]
///   [botLeft] [botRight]
class TerrainTile {
  TileType type;

  /// For brick tiles: which quadrants remain intact.
  /// Index: 0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight
  List<bool> quadrants;

  TerrainTile({
    required this.type,
    List<bool>? quadrants,
  }) : quadrants = quadrants ?? [true, true, true, true];

  /// Whether this tile blocks tank movement.
  bool get blocksTanks =>
      type == TileType.brick ||
      type == TileType.steel ||
      type == TileType.water ||
      type == TileType.base;

  /// Whether this tile blocks bullets.
  bool get blocksBullets =>
      type == TileType.brick ||
      type == TileType.steel ||
      type == TileType.base;

  /// Whether all quadrants of a brick have been destroyed.
  bool get isFullyDestroyed =>
      type == TileType.brick && !quadrants.contains(true);

  /// Destroy specific quadrants hit by a bullet.
  /// Returns true if any quadrant was actually destroyed.
  bool destroyQuadrants(List<int> indices) {
    if (type != TileType.brick) return false;
    bool anyDestroyed = false;
    for (final i in indices) {
      if (i >= 0 && i < 4 && quadrants[i]) {
        quadrants[i] = false;
        anyDestroyed = true;
      }
    }
    return anyDestroyed;
  }

  /// Reset tile (used for stage reload).
  void reset(TileType newType) {
    type = newType;
    quadrants = [true, true, true, true];
  }
}
