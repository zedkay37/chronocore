import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'storage_service.dart';

/// Service de gestion des Fragments de Temps
class TimeFragmentService extends ChangeNotifier {
  static TimeFragmentService? _instance;
  
  TimeFragmentCollection _fragments = const TimeFragmentCollection([]);
  int _currentBalance = 0;
  
  final StorageService _storage = StorageService.instance;
  final StreamController<TimeFragment> _fragmentStreamController = StreamController<TimeFragment>.broadcast();

  TimeFragmentService._();

  static TimeFragmentService get instance {
    _instance ??= TimeFragmentService._();
    return _instance!;
  }

  /// Stream des nouveaux fragments gagnés
  Stream<TimeFragment> get newFragmentStream => _fragmentStreamController.stream;

  /// Collection actuelle de fragments
  TimeFragmentCollection get fragments => _fragments;

  /// Solde actuel de FT
  int get currentBalance => _currentBalance;

  /// FT gagnés aujourd'hui
  int get todayEarned => _fragments.todayAmount;

  /// Total des FT gagnés
  int get totalEarned => _fragments.totalAmount;

  /// FT par source
  int getEarnedBySource(FragmentSource source) => _fragments.getAmountBySource(source);

  /// Initialiser le service
  Future<void> initialize() async {
    await _loadFragments();
  }

  /// Charger les fragments depuis le stockage
  Future<void> _loadFragments() async {
    try {
      _fragments = await _storage.loadTimeFragments();
      _currentBalance = _fragments.totalAmount;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des fragments: $e');
      _fragments = const TimeFragmentCollection([]);
      _currentBalance = 0;
    }
  }

  /// Gagner des FT depuis une session Pomodoro
  Future<void> earnFromPomodoro({
    required Duration sessionDuration,
    required Duration actualDuration,
    required bool wasCompleted,
    required bool wasAppLeft,
    required Duration timeOutOfApp,
  }) async {
    final ftEarned = PomodoroSession.calculateFTEarned(
      sessionDuration: sessionDuration,
      actualDuration: actualDuration,
      wasCompleted: wasCompleted,
      wasAppLeft: wasAppLeft,
      timeOutOfApp: timeOutOfApp,
    );

    if (ftEarned > 0) {
      await _addFragment(TimeFragment.create(
        amount: ftEarned,
        source: FragmentSource.pomodoro,
        metadata: {
          'sessionDuration': sessionDuration.inMinutes,
          'actualDuration': actualDuration.inMinutes,
          'wasCompleted': wasCompleted,
          'wasAppLeft': wasAppLeft,
          'timeOutOfApp': timeOutOfApp.inSeconds,
        },
      ));
    }
  }

  /// Gagner des FT depuis la marche
  Future<void> earnFromWalking(int steps) async {
    final ftEarned = steps ~/ 100; // 100 pas = 1 FT
    
    if (ftEarned > 0) {
      await _addFragment(TimeFragment.create(
        amount: ftEarned,
        source: FragmentSource.walking,
        metadata: {
          'steps': steps,
          'conversionRate': 100,
        },
      ));
    }
  }

  /// Gagner des FT en bonus
  Future<void> earnBonus({
    required int amount,
    required String reason,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    await _addFragment(TimeFragment.create(
      amount: amount,
      source: FragmentSource.bonus,
      metadata: {
        'reason': reason,
        ...?additionalMetadata,
      },
    ));
  }

  /// Gagner des FT depuis un achievement
  Future<void> earnFromAchievement(Achievement achievement) async {
    await _addFragment(TimeFragment.create(
      amount: achievement.ftReward,
      source: FragmentSource.achievement,
      metadata: {
        'achievementId': achievement.id,
        'achievementName': achievement.name,
        'achievementType': achievement.type.name,
      },
    ));
  }

  /// Ajouter un fragment privé
  Future<void> _addFragment(TimeFragment fragment) async {
    try {
      // Sauvegarder en base
      await _storage.saveTimeFragment(fragment);
      
      // Mettre à jour la collection
      _fragments = _fragments.add(fragment);
      _currentBalance += fragment.amount;
      
      // Notifier les listeners
      notifyListeners();
      _fragmentStreamController.add(fragment);
      
      debugPrint('Fragment gagné: ${fragment.amount} FT (${fragment.source.name}) - Total: $_currentBalance');
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du fragment: $e');
      rethrow;
    }
  }

  /// Dépenser des FT
  Future<bool> spend(int amount, String reason) async {
    if (amount > _currentBalance) {
      debugPrint('Solde insuffisant: $_currentBalance < $amount');
      return false;
    }

    try {
      _currentBalance -= amount;
      notifyListeners();
      
      debugPrint('FT dépensés: $amount pour $reason - Solde restant: $_currentBalance');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la dépense: $e');
      // Restaurer le solde en cas d'erreur
      _currentBalance += amount;
      return false;
    }
  }

  /// Vérifier si on peut dépenser un montant
  bool canSpend(int amount) => amount <= _currentBalance;

  /// Obtenir un temps d'exploration basé sur les FT disponibles
  int getAvailableExplorationMinutes() {
    // 10 FT = 1 minute d'exploration
    return _currentBalance ~/ 10;
  }

  /// Acheter du temps d'exploration
  Future<int> buyExplorationTime(int minutes) async {
    final cost = minutes * 10; // 10 FT par minute
    
    if (await spend(cost, 'Temps d\'exploration ($minutes min)')) {
      return minutes;
    }
    
    return 0; // Échec de l'achat
  }

  /// Révéler une tuile
  Future<bool> revealTile(TileType tileType) async {
    final cost = MapTile.getCostForType(tileType);
    return await spend(cost, 'Révélation tuile (${tileType.name})');
  }

  /// Activer une structure
  Future<bool> activateStructure(Structure structure) async {
    return await spend(structure.activationCost, 'Activation structure (${structure.type.name})');
  }

  /// Acheter un soutien de combat
  Future<bool> buyCombatSupport() async {
    return await spend(50, 'Soutien de combat');
  }

  /// Statistiques détaillées
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todayFragments = _fragments.fragments
        .where((f) => f.earnedAt.isAfter(today))
        .toList();
    
    final thisWeekStart = today.subtract(Duration(days: now.weekday - 1));
    final weekFragments = _fragments.fragments
        .where((f) => f.earnedAt.isAfter(thisWeekStart))
        .toList();

    return {
      'currentBalance': _currentBalance,
      'totalEarned': totalEarned,
      'todayEarned': todayEarned,
      'weekEarned': weekFragments.fold(0, (sum, f) => sum + f.amount),
      'pomodoroTotal': getEarnedBySource(FragmentSource.pomodoro),
      'walkingTotal': getEarnedBySource(FragmentSource.walking),
      'bonusTotal': getEarnedBySource(FragmentSource.bonus),
      'achievementTotal': getEarnedBySource(FragmentSource.achievement),
      'fragmentCount': _fragments.fragments.length,
      'todayFragmentCount': todayFragments.length,
      'averagePerFragment': _fragments.fragments.isNotEmpty 
          ? totalEarned / _fragments.fragments.length 
          : 0,
    };
  }

  /// Nettoyer les anciens fragments (garder seulement les 30 derniers jours)
  Future<void> cleanupOldFragments() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    final recentFragments = _fragments.fragments
        .where((f) => f.earnedAt.isAfter(cutoffDate))
        .toList();
    
    if (recentFragments.length < _fragments.fragments.length) {
      _fragments = TimeFragmentCollection(recentFragments);
      debugPrint('Nettoyage des anciens fragments: ${_fragments.fragments.length} conservés');
    }
  }

  /// Réinitialiser le service
  Future<void> reset() async {
    _fragments = const TimeFragmentCollection([]);
    _currentBalance = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _fragmentStreamController.close();
    super.dispose();
  }
}