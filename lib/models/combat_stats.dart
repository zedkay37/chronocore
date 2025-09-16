/// Statistiques de combat du joueur
class CombatStats {
  final int health;
  final int maxHealth;
  final int attack;
  final int defense;
  final int criticalChance; // en pourcentage
  final double attackSpeed; // attaques par seconde
  final int experience;
  final int level;

  const CombatStats({
    this.health = 100,
    this.maxHealth = 100,
    this.attack = 10,
    this.defense = 5,
    this.criticalChance = 5,
    this.attackSpeed = 1.0,
    this.experience = 0,
    this.level = 1,
  });

  /// Stats de base initiales
  factory CombatStats.initial() {
    return const CombatStats();
  }

  /// Calculer les dégâts d'attaque
  int calculateDamage({bool isCritical = false}) {
    final baseDamage = attack;
    if (isCritical) {
      return (baseDamage * 1.5).round();
    }
    return baseDamage;
  }

  /// Calculer les dégâts reçus après défense
  int calculateDamageReceived(int incomingDamage) {
    final reducedDamage = (incomingDamage - defense).clamp(1, incomingDamage);
    return reducedDamage;
  }

  /// Appliquer des dégâts
  CombatStats takeDamage(int damage) {
    final actualDamage = calculateDamageReceived(damage);
    final newHealth = (health - actualDamage).clamp(0, maxHealth);
    return copyWith(health: newHealth);
  }

  /// Soigner
  CombatStats heal(int amount) {
    final newHealth = (health + amount).clamp(0, maxHealth);
    return copyWith(health: newHealth);
  }

  /// Restaurer complètement la santé
  CombatStats fullHeal() {
    return copyWith(health: maxHealth);
  }

  /// Calculer si c'est un coup critique
  bool rollCritical() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return random < criticalChance;
  }

  /// Augmenter le niveau
  CombatStats levelUp() {
    return copyWith(
      level: level + 1,
      maxHealth: maxHealth + 20,
      health: maxHealth + 20, // Heal complet au niveau suivant
      attack: attack + 2,
      defense: defense + 1,
      criticalChance: (criticalChance + 1).clamp(0, 25), // Cap à 25%
    );
  }

  /// Appliquer un boost temporaire
  CombatStats applyBoost({
    int? healthBoost,
    int? attackBoost,
    int? defenseBoost,
    int? criticalBoost,
    double? speedBoost,
  }) {
    return copyWith(
      health: healthBoost != null ? (health + healthBoost).clamp(0, maxHealth) : health,
      attack: attackBoost != null ? attack + attackBoost : attack,
      defense: defenseBoost != null ? defense + defenseBoost : defense,
      criticalChance: criticalBoost != null 
          ? (criticalChance + criticalBoost).clamp(0, 50) 
          : criticalChance,
      attackSpeed: speedBoost != null ? attackSpeed + speedBoost : attackSpeed,
    );
  }

  /// Pourcentage de santé
  double get healthPercentage => health / maxHealth;

  /// Est-ce que le joueur est mort
  bool get isDead => health <= 0;

  /// Est-ce que le joueur est en pleine santé
  bool get isFullHealth => health == maxHealth;

  /// Méthode copyWith pour l'immutabilité
  CombatStats copyWith({
    int? health,
    int? maxHealth,
    int? attack,
    int? defense,
    int? criticalChance,
    double? attackSpeed,
    int? experience,
    int? level,
  }) {
    return CombatStats(
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      criticalChance: criticalChance ?? this.criticalChance,
      attackSpeed: attackSpeed ?? this.attackSpeed,
      experience: experience ?? this.experience,
      level: level ?? this.level,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'health': health,
      'maxHealth': maxHealth,
      'attack': attack,
      'defense': defense,
      'criticalChance': criticalChance,
      'attackSpeed': attackSpeed,
      'experience': experience,
      'level': level,
    };
  }

  /// Création depuis JSON
  factory CombatStats.fromJson(Map<String, dynamic> json) {
    return CombatStats(
      health: json['health'] as int? ?? 100,
      maxHealth: json['maxHealth'] as int? ?? 100,
      attack: json['attack'] as int? ?? 10,
      defense: json['defense'] as int? ?? 5,
      criticalChance: json['criticalChance'] as int? ?? 5,
      attackSpeed: (json['attackSpeed'] as num?)?.toDouble() ?? 1.0,
      experience: json['experience'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
    );
  }

  @override
  String toString() {
    return 'CombatStats{level: $level, health: $health/$maxHealth, attack: $attack, defense: $defense}';
  }
}

/// Types d'ennemis
enum EnemyType {
  slime,    // Slimes faibles (vagues 1-3)
  golem,    // Golems (vagues 4-6)
  shadow,   // Ombres rapides (vagues 7-9)
  boss,     // Boss (vague 10)
}

/// Ennemi avec stats et comportement
class Enemy {
  final String id;
  final EnemyType type;
  final String name;
  final CombatStats stats;
  final bool isAlive;
  final Map<String, dynamic> properties;

  const Enemy({
    required this.id,
    required this.type,
    required this.name,
    required this.stats,
    this.isAlive = true,
    this.properties = const {},
  });

  /// Créer un ennemi selon le type et la vague
  factory Enemy.create({
    required String id,
    required EnemyType type,
    required int wave,
  }) {
    late String name;
    late CombatStats stats;

    switch (type) {
      case EnemyType.slime:
        name = 'Slime de niveau $wave';
        stats = CombatStats(
          health: 10 + (wave * 2),
          maxHealth: 10 + (wave * 2),
          attack: 5 + wave,
          defense: 1,
          criticalChance: 0,
          attackSpeed: 0.8,
        );
        break;
      case EnemyType.golem:
        name = 'Golem Ancien';
        stats = CombatStats(
          health: 25 + (wave * 3),
          maxHealth: 25 + (wave * 3),
          attack: 8 + wave,
          defense: 3,
          criticalChance: 5,
          attackSpeed: 0.6,
        );
        break;
      case EnemyType.shadow:
        name = 'Ombre Rapide';
        stats = CombatStats(
          health: 15 + wave,
          maxHealth: 15 + wave,
          attack: 12 + wave,
          defense: 1,
          criticalChance: 15,
          attackSpeed: 1.5,
        );
        break;
      case EnemyType.boss:
        name = 'Gardien Temporel';
        stats = CombatStats(
          health: 200,
          maxHealth: 200,
          attack: 15,
          defense: 5,
          criticalChance: 20,
          attackSpeed: 1.0,
        );
        break;
    }

    return Enemy(
      id: id,
      type: type,
      name: name,
      stats: stats,
    );
  }

  /// Appliquer des dégâts à l'ennemi
  Enemy takeDamage(int damage) {
    final newStats = stats.takeDamage(damage);
    return copyWith(
      stats: newStats,
      isAlive: newStats.health > 0,
    );
  }

  /// Calculer les dégâts d'attaque de l'ennemi
  int calculateAttackDamage() {
    final isCritical = stats.rollCritical();
    return stats.calculateDamage(isCritical: isCritical);
  }

  /// Méthode copyWith pour l'immutabilité
  Enemy copyWith({
    String? id,
    EnemyType? type,
    String? name,
    CombatStats? stats,
    bool? isAlive,
    Map<String, dynamic>? properties,
  }) {
    return Enemy(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      stats: stats ?? this.stats,
      isAlive: isAlive ?? this.isAlive,
      properties: properties ?? this.properties,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'stats': stats.toJson(),
      'isAlive': isAlive,
      'properties': properties,
    };
  }

  /// Création depuis JSON
  factory Enemy.fromJson(Map<String, dynamic> json) {
    return Enemy(
      id: json['id'] as String,
      type: EnemyType.values.firstWhere((e) => e.name == json['type']),
      name: json['name'] as String,
      stats: CombatStats.fromJson(json['stats'] as Map<String, dynamic>),
      isAlive: json['isAlive'] as bool? ?? true,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'Enemy{name: $name, type: $type, isAlive: $isAlive, stats: $stats}';
  }
}