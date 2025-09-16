/// Position du joueur dans le monde
class PlayerPosition {
  final double x;
  final double y;
  final int worldLevel;

  const PlayerPosition({
    required this.x,
    required this.y,
    required this.worldLevel,
  });

  /// Position par défaut (centre du monde 1)
  factory PlayerPosition.defaultPosition() {
    return const PlayerPosition(x: 0.0, y: 0.0, worldLevel: 1);
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'worldLevel': worldLevel,
    };
  }

  /// Création depuis JSON
  factory PlayerPosition.fromJson(Map<String, dynamic> json) {
    return PlayerPosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      worldLevel: json['worldLevel'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerPosition &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          worldLevel == other.worldLevel;

  @override
  int get hashCode => Object.hash(x, y, worldLevel);
}

/// Types de tuiles du monde
enum TileType {
  terrain,        // Sol de base
  stele,         // Stèle mystique
  bridge,        // Pont ancien
  relic,         // Relique temporelle
  bossPortal,    // Portail boss
  water,         // Eau
  forest,        // Forêt
  mountain,      // Montagne
}

/// Tuile de la carte
class MapTile {
  final int x;
  final int y;
  final TileType type;
  final bool isRevealed;
  final bool isInteractable;
  final int ftCostToReveal;
  final Map<String, dynamic> properties;

  const MapTile({
    required this.x,
    required this.y,
    required this.type,
    this.isRevealed = false,
    this.isInteractable = false,
    this.ftCostToReveal = 20,
    this.properties = const {},
  });

  /// Coût en FT selon le type de tuile
  static int getCostForType(TileType type) {
    switch (type) {
      case TileType.terrain:
        return 0;
      case TileType.stele:
        return 50;
      case TileType.bridge:
        return 100;
      case TileType.relic:
        return 200;
      case TileType.bossPortal:
        return 500;
      case TileType.water:
      case TileType.forest:
      case TileType.mountain:
        return 30;
    }
  }

  /// Créer une tuile révélée
  MapTile reveal() {
    return MapTile(
      x: x,
      y: y,
      type: type,
      isRevealed: true,
      isInteractable: type != TileType.terrain,
      ftCostToReveal: ftCostToReveal,
      properties: properties,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'type': type.name,
      'isRevealed': isRevealed,
      'isInteractable': isInteractable,
      'ftCostToReveal': ftCostToReveal,
      'properties': properties,
    };
  }

  /// Création depuis JSON
  factory MapTile.fromJson(Map<String, dynamic> json) {
    return MapTile(
      x: json['x'] as int,
      y: json['y'] as int,
      type: TileType.values.firstWhere((e) => e.name == json['type']),
      isRevealed: json['isRevealed'] as bool? ?? false,
      isInteractable: json['isInteractable'] as bool? ?? false,
      ftCostToReveal: json['ftCostToReveal'] as int? ?? 20,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapTile &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Types de structures
enum StructureType {
  stele,
  bridge,
  relic,
  bossPortal,
}

/// Structure interactive dans le monde
class Structure {
  final String id;
  final StructureType type;
  final int x;
  final int y;
  final bool isActivated;
  final int activationCost;
  final Map<String, dynamic> rewards;
  final Map<String, dynamic> properties;

  const Structure({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.isActivated = false,
    required this.activationCost,
    this.rewards = const {},
    this.properties = const {},
  });

  /// Activer la structure
  Structure activate() {
    return Structure(
      id: id,
      type: type,
      x: x,
      y: y,
      isActivated: true,
      activationCost: activationCost,
      rewards: rewards,
      properties: properties,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'x': x,
      'y': y,
      'isActivated': isActivated,
      'activationCost': activationCost,
      'rewards': rewards,
      'properties': properties,
    };
  }

  /// Création depuis JSON
  factory Structure.fromJson(Map<String, dynamic> json) {
    return Structure(
      id: json['id'] as String,
      type: StructureType.values.firstWhere((e) => e.name == json['type']),
      x: json['x'] as int,
      y: json['y'] as int,
      isActivated: json['isActivated'] as bool? ?? false,
      activationCost: json['activationCost'] as int,
      rewards: Map<String, dynamic>.from(json['rewards'] ?? {}),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }
}

/// État complet du monde
class WorldState {
  final String id;
  final int worldLevel;
  final List<MapTile> revealedTiles;
  final List<Structure> activeStructures;
  final PlayerPosition currentPosition;
  final int explorationTimeRemaining; // en minutes
  final bool isBossUnlocked;
  final DateTime lastUpdated;

  const WorldState({
    required this.id,
    required this.worldLevel,
    this.revealedTiles = const [],
    this.activeStructures = const [],
    required this.currentPosition,
    this.explorationTimeRemaining = 0,
    this.isBossUnlocked = false,
    required this.lastUpdated,
  });

  /// État initial du monde 1
  factory WorldState.initial() {
    final now = DateTime.now();
    return WorldState(
      id: 'world_1_${now.millisecondsSinceEpoch}',
      worldLevel: 1,
      revealedTiles: [
        // Tuile de départ révélée
        const MapTile(
          x: 0,
          y: 0,
          type: TileType.terrain,
          isRevealed: true,
        ),
      ],
      currentPosition: PlayerPosition.defaultPosition(),
      lastUpdated: now,
    );
  }

  /// Ajouter du temps d'exploration
  WorldState addExplorationTime(int minutes) {
    final newTime = (explorationTimeRemaining + minutes).clamp(0, 45); // Cap à 45min
    return copyWith(explorationTimeRemaining: newTime);
  }

  /// Révéler de nouvelles tuiles
  WorldState revealTiles(List<MapTile> newTiles) {
    final updatedTiles = [...revealedTiles];
    for (final tile in newTiles) {
      if (!updatedTiles.any((t) => t.x == tile.x && t.y == tile.y)) {
        updatedTiles.add(tile.reveal());
      }
    }
    return copyWith(revealedTiles: updatedTiles);
  }

  /// Déplacer le joueur
  WorldState movePlayer(double x, double y) {
    return copyWith(
      currentPosition: PlayerPosition(
        x: x,
        y: y,
        worldLevel: currentPosition.worldLevel,
      ),
    );
  }

  /// Méthode copyWith pour l'immutabilité
  WorldState copyWith({
    String? id,
    int? worldLevel,
    List<MapTile>? revealedTiles,
    List<Structure>? activeStructures,
    PlayerPosition? currentPosition,
    int? explorationTimeRemaining,
    bool? isBossUnlocked,
    DateTime? lastUpdated,
  }) {
    return WorldState(
      id: id ?? this.id,
      worldLevel: worldLevel ?? this.worldLevel,
      revealedTiles: revealedTiles ?? this.revealedTiles,
      activeStructures: activeStructures ?? this.activeStructures,
      currentPosition: currentPosition ?? this.currentPosition,
      explorationTimeRemaining: explorationTimeRemaining ?? this.explorationTimeRemaining,
      isBossUnlocked: isBossUnlocked ?? this.isBossUnlocked,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worldLevel': worldLevel,
      'revealedTiles': revealedTiles.map((t) => t.toJson()).toList(),
      'activeStructures': activeStructures.map((s) => s.toJson()).toList(),
      'currentPosition': currentPosition.toJson(),
      'explorationTimeRemaining': explorationTimeRemaining,
      'isBossUnlocked': isBossUnlocked,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Création depuis JSON
  factory WorldState.fromJson(Map<String, dynamic> json) {
    return WorldState(
      id: json['id'] as String,
      worldLevel: json['worldLevel'] as int,
      revealedTiles: (json['revealedTiles'] as List<dynamic>)
          .map((item) => MapTile.fromJson(item as Map<String, dynamic>))
          .toList(),
      activeStructures: (json['activeStructures'] as List<dynamic>)
          .map((item) => Structure.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPosition: PlayerPosition.fromJson(json['currentPosition'] as Map<String, dynamic>),
      explorationTimeRemaining: json['explorationTimeRemaining'] as int? ?? 0,
      isBossUnlocked: json['isBossUnlocked'] as bool? ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}