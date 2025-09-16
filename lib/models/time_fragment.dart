import 'dart:math';

/// Énumération des sources de génération de Fragments de Temps
enum FragmentSource {
  pomodoro,
  walking,
  bonus,
  achievement
}

/// Fragment de Temps (FT) - Ressource centrale du jeu
/// Généré par sessions Pomodoro et marche, utilisé pour débloquer du contenu
class TimeFragment {
  final String id;
  final int amount;
  final DateTime earnedAt;
  final FragmentSource source;
  final Map<String, dynamic> metadata;

  const TimeFragment({
    required this.id,
    required this.amount,
    required this.earnedAt,
    required this.source,
    this.metadata = const {},
  });

  /// Constructeur factory pour créer un nouveau fragment
  factory TimeFragment.create({
    required int amount,
    required FragmentSource source,
    Map<String, dynamic>? metadata,
  }) {
    return TimeFragment(
      id: _generateId(),
      amount: amount,
      earnedAt: DateTime.now(),
      source: source,
      metadata: metadata ?? {},
    );
  }

  /// Générer un ID unique simple
  static String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999);
    return 'ft_${timestamp}_$randomPart';
  }

  /// Conversion vers JSON pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'earnedAt': earnedAt.toIso8601String(),
      'source': source.name,
      'metadata': metadata,
    };
  }

  /// Création depuis JSON
  factory TimeFragment.fromJson(Map<String, dynamic> json) {
    return TimeFragment(
      id: json['id'] as String,
      amount: json['amount'] as int,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      source: FragmentSource.values.firstWhere(
        (e) => e.name == json['source'],
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeFragment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TimeFragment{id: $id, amount: $amount, source: $source, earnedAt: $earnedAt}';
  }
}

/// Collection de fragments avec méthodes utilitaires
class TimeFragmentCollection {
  final List<TimeFragment> fragments;

  const TimeFragmentCollection(this.fragments);

  /// Total des FT dans la collection
  int get totalAmount => fragments.fold(0, (sum, ft) => sum + ft.amount);

  /// FT gagnés aujourd'hui
  int get todayAmount {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    return fragments
        .where((ft) => ft.earnedAt.isAfter(todayStart))
        .fold(0, (sum, ft) => sum + ft.amount);
  }

  /// FT par source
  int getAmountBySource(FragmentSource source) {
    return fragments
        .where((ft) => ft.source == source)
        .fold(0, (sum, ft) => sum + ft.amount);
  }

  /// Ajouter un fragment
  TimeFragmentCollection add(TimeFragment fragment) {
    return TimeFragmentCollection([...fragments, fragment]);
  }

  /// Conversion vers JSON
  List<Map<String, dynamic>> toJson() {
    return fragments.map((ft) => ft.toJson()).toList();
  }

  /// Création depuis JSON
  factory TimeFragmentCollection.fromJson(List<dynamic> json) {
    final fragments = json
        .map((item) => TimeFragment.fromJson(item as Map<String, dynamic>))
        .toList();
    return TimeFragmentCollection(fragments);
  }
}