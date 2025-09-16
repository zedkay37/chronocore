import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/models.dart';
import '../../services/services.dart';
import 'step_validator.dart';

/// Service de comptage des pas avec validation anti-triche
class StepCounter extends ChangeNotifier {
  static StepCounter? _instance;
  
  bool _isTracking = false;
  bool _hasPermission = false;
  int _currentSteps = 0;
  int _dailySteps = 0;
  int _sessionStartSteps = 0;
  DateTime? _lastUpdateTime;
  
  StreamSubscription<StepCount>? _stepCountSubscription;
  final StepValidator _validator = StepValidator();
  final GameService _gameService = GameService.instance;
  Timer? _periodicSyncTimer;

  StepCounter._();

  static StepCounter get instance {
    _instance ??= StepCounter._();
    return _instance!;
  }

  /// État du suivi
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  int get currentSteps => _currentSteps;
  int get dailySteps => _dailySteps;
  int get sessionSteps => _currentSteps - _sessionStartSteps;

  /// FT gagnés depuis les pas
  int get ftFromSteps => _currentSteps ~/ 100;
  int get dailyFTFromSteps => _dailySteps ~/ 100;

  /// Objectif quotidien
  int get dailyGoal => 10000;
  double get dailyProgress => (_dailySteps / dailyGoal).clamp(0.0, 1.0);
  bool get isDailyGoalReached => _dailySteps >= dailyGoal;

  /// Initialiser le service
  Future<void> initialize() async {
    await _requestPermissions();
    if (_hasPermission) {
      await _loadStoredSteps();
    }
  }

  /// Demander les permissions nécessaires
  Future<void> _requestPermissions() async {
    try {
      // Vérifier les permissions pour le podomètre
      final status = await Permission.activityRecognition.request();
      _hasPermission = status.isGranted;
      
      if (!_hasPermission) {
        debugPrint('Permission de reconnaissance d\'activité refusée');
      } else {
        debugPrint('Permissions accordées pour le podomètre');
      }
    } catch (e) {
      debugPrint('Erreur lors de la demande de permissions: $e');
      _hasPermission = false;
    }
  }

  /// Charger les pas stockés
  Future<void> _loadStoredSteps() async {
    try {
      final progress = await StorageService.instance.loadPlayerProgress();
      if (progress != null) {
        _dailySteps = progress.dailySteps;
        _currentSteps = progress.totalStepsTaken;
        debugPrint('Pas chargés: quotidien=$_dailySteps, total=$_currentSteps');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des pas: $e');
    }
  }

  /// Démarrer le suivi des pas
  Future<bool> startTracking() async {
    if (_isTracking) {
      debugPrint('Suivi déjà actif');
      return true;
    }

    if (!_hasPermission) {
      debugPrint('Permissions manquantes pour le suivi des pas');
      return false;
    }

    try {
      // Obtenir le nombre de pas initial
      _sessionStartSteps = _currentSteps;
      
      // S'abonner au stream des pas
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      // Démarrer la synchronisation périodique
      _startPeriodicSync();
      
      _isTracking = true;
      notifyListeners();
      
      debugPrint('Suivi des pas démarré');
      return true;
    } catch (e) {
      debugPrint('Erreur lors du démarrage du suivi: $e');
      return false;
    }
  }

  /// Arrêter le suivi des pas
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    
    _isTracking = false;
    
    // Synchroniser une dernière fois
    await _syncWithGameService();
    
    notifyListeners();
    debugPrint('Suivi des pas arrêté');
  }

  /// Gestionnaire de nouveaux pas
  void _onStepCount(StepCount stepCount) {
    final now = DateTime.now();
    final newSteps = stepCount.steps;
    
    // Calculer l'incrément de pas
    int increment = 0;
    if (_lastUpdateTime != null && newSteps > _currentSteps) {
      increment = newSteps - _currentSteps;
    } else if (_lastUpdateTime == null) {
      // Premier update, prendre en compte tous les pas du jour
      increment = newSteps;
    }

    if (increment > 0) {
      // Valider l'incrément
      final validatedIncrement = _validator.filterAnomalousSteps(increment, now);
      
      if (validatedIncrement > 0) {
        _updateSteps(newSteps, validatedIncrement, now);
      }
    }

    _lastUpdateTime = now;
  }

  /// Mettre à jour les pas
  void _updateSteps(int totalSteps, int increment, DateTime timestamp) {
    _currentSteps = totalSteps;
    _dailySteps += increment;
    
    debugPrint('Pas mis à jour: +$increment (total: $_currentSteps, quotidien: $_dailySteps)');
    notifyListeners();
  }

  /// Gestionnaire d'erreur des pas
  void _onStepCountError(error) {
    debugPrint('Erreur du podomètre: $error');
    
    // Essayer de redémarrer après un délai
    Timer(const Duration(seconds: 5), () {
      if (_isTracking) {
        _restartTracking();
      }
    });
  }

  /// Redémarrer le suivi
  Future<void> _restartTracking() async {
    debugPrint('Redémarrage du suivi des pas...');
    await stopTracking();
    await Future.delayed(const Duration(seconds: 1));
    await startTracking();
  }

  /// Démarrer la synchronisation périodique
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _syncWithGameService();
    });
  }

  /// Synchroniser avec le service de jeu
  Future<void> _syncWithGameService() async {
    try {
      final newSteps = sessionSteps;
      if (newSteps > 0) {
        await _gameService.addSteps(newSteps);
        _sessionStartSteps = _currentSteps; // Reset session counter
        debugPrint('$newSteps pas synchronisés avec le service de jeu');
      }
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation: $e');
    }
  }

  /// Calculer les FT générés par les pas
  int calculateFTFromSteps() {
    return _currentSteps ~/ 100; // 100 pas = 1 FT
  }

  /// Obtenir la progression quotidienne
  Map<String, dynamic> getDailyProgress() {
    return _validator.calculateDailyProgress();
  }

  /// Obtenir les statistiques complètes
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final sessionDuration = _lastUpdateTime != null 
        ? now.difference(_lastUpdateTime!) 
        : Duration.zero;

    return {
      'isTracking': _isTracking,
      'hasPermission': _hasPermission,
      'currentSteps': _currentSteps,
      'dailySteps': _dailySteps,
      'sessionSteps': sessionSteps,
      'dailyGoal': dailyGoal,
      'dailyProgress': dailyProgress,
      'isDailyGoalReached': isDailyGoalReached,
      'ftFromSteps': ftFromSteps,
      'dailyFTFromSteps': dailyFTFromSteps,
      'sessionDuration': sessionDuration.inMinutes,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'validator': _validator.getValidationStatistics(),
    };
  }

  /// Forcer une synchronisation manuelle
  Future<void> forceSyncNow() async {
    await _syncWithGameService();
    debugPrint('Synchronisation manuelle effectuée');
  }

  /// Réinitialiser le compteur (pour debug/test)
  void resetCounter() {
    _currentSteps = 0;
    _dailySteps = 0;
    _sessionStartSteps = 0;
    _lastUpdateTime = null;
    _validator.reset();
    
    notifyListeners();
    debugPrint('Compteur de pas réinitialisé');
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}