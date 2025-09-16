import 'package:flutter/foundation.dart';

/// Validateur de données de pas pour éviter la triche
class StepValidator {
  static const int maxDailySteps = 20000; // Maximum théorique par jour
  static const int maxStepsPerMinute = 200; // Maximum théorique par minute
  static const int minStepInterval = 300; // Minimum 300ms entre les pas
  
  final List<DateTime> _recentStepTimes = [];
  DateTime? _lastValidationTime;
  int _dailyStepCount = 0;
  DateTime? _lastDayReset;

  /// Valider les données de pas
  bool validateStepData({
    required int newSteps,
    required DateTime timestamp,
  }) {
    // Reset quotidien
    _resetDailyCountIfNeeded(timestamp);

    // Vérifier si les nouveaux pas sont raisonnables
    if (!_validateStepIncrement(newSteps, timestamp)) {
      debugPrint('Validation échouée: incrément de pas suspect ($newSteps pas)');
      return false;
    }

    // Vérifier le rythme des pas
    if (!_validateStepRate(newSteps, timestamp)) {
      debugPrint('Validation échouée: rythme de pas trop élevé');
      return false;
    }

    // Vérifier la limite quotidienne
    if (!_validateDailyLimit(newSteps)) {
      debugPrint('Validation échouée: limite quotidienne dépassée');
      return false;
    }

    // Validation réussie
    _recordValidSteps(newSteps, timestamp);
    return true;
  }

  /// Valider l'incrément de pas
  bool _validateStepIncrement(int newSteps, DateTime timestamp) {
    // Vérifier que l'incrément n'est pas négatif
    if (newSteps < 0) return false;

    // Vérifier que l'incrément n'est pas trop important
    if (_lastValidationTime != null) {
      final timeDiff = timestamp.difference(_lastValidationTime!);
      final maxPossibleSteps = (timeDiff.inMinutes * maxStepsPerMinute).ceil();
      
      if (newSteps > maxPossibleSteps) {
        return false;
      }
    }

    return true;
  }

  /// Valider le rythme des pas
  bool _validateStepRate(int newSteps, DateTime timestamp) {
    // Ajouter les timestamps des nouveaux pas
    for (int i = 0; i < newSteps; i++) {
      _recentStepTimes.add(timestamp);
    }

    // Garder seulement les pas de la dernière minute
    final oneMinuteAgo = timestamp.subtract(const Duration(minutes: 1));
    _recentStepTimes.removeWhere((time) => time.isBefore(oneMinuteAgo));

    // Vérifier le taux de pas par minute
    if (_recentStepTimes.length > maxStepsPerMinute) {
      return false;
    }

    return true;
  }

  /// Valider la limite quotidienne
  bool _validateDailyLimit(int newSteps) {
    return (_dailyStepCount + newSteps) <= maxDailySteps;
  }

  /// Enregistrer les pas valides
  void _recordValidSteps(int steps, DateTime timestamp) {
    _dailyStepCount += steps;
    _lastValidationTime = timestamp;
  }

  /// Réinitialiser le compteur quotidien si nécessaire
  void _resetDailyCountIfNeeded(DateTime currentTime) {
    final currentDay = DateTime(currentTime.year, currentTime.month, currentTime.day);
    
    if (_lastDayReset == null || _lastDayReset!.isBefore(currentDay)) {
      _dailyStepCount = 0;
      _lastDayReset = currentDay;
      _recentStepTimes.clear();
      debugPrint('Compteur quotidien de pas réinitialisé');
    }
  }

  /// Filtrer les pas anormaux
  int filterAnomalousSteps(int rawSteps, DateTime timestamp) {
    if (validateStepData(newSteps: rawSteps, timestamp: timestamp)) {
      return rawSteps;
    }

    // Si la validation échoue, retourner un nombre de pas plus conservateur
    if (_lastValidationTime != null) {
      final timeDiff = timestamp.difference(_lastValidationTime!);
      final conservativeSteps = (timeDiff.inMinutes * (maxStepsPerMinute * 0.5)).floor();
      return conservativeSteps.clamp(0, rawSteps);
    }

    return 0;
  }

  /// Calculer la progression quotidienne
  Map<String, dynamic> calculateDailyProgress() {
    const targetSteps = 10000; // Objectif quotidien standard
    final progressPercentage = (_dailyStepCount / targetSteps).clamp(0.0, 1.0);
    
    return {
      'dailySteps': _dailyStepCount,
      'targetSteps': targetSteps,
      'progressPercentage': progressPercentage,
      'isTargetReached': _dailyStepCount >= targetSteps,
      'remainingSteps': (targetSteps - _dailyStepCount).clamp(0, targetSteps),
    };
  }

  /// Obtenir les statistiques de validation
  Map<String, dynamic> getValidationStatistics() {
    return {
      'dailyStepCount': _dailyStepCount,
      'lastValidationTime': _lastValidationTime?.toIso8601String(),
      'lastDayReset': _lastDayReset?.toIso8601String(),
      'recentStepTimeCount': _recentStepTimes.length,
      'maxDailySteps': maxDailySteps,
      'maxStepsPerMinute': maxStepsPerMinute,
    };
  }

  /// Réinitialiser le validateur
  void reset() {
    _recentStepTimes.clear();
    _lastValidationTime = null;
    _dailyStepCount = 0;
    _lastDayReset = null;
  }
}