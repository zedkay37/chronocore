import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';

/// Service de suivi du focus utilisateur pour les sessions Pomodoro
class FocusTracker extends ChangeNotifier {
  bool _isAppInForeground = true;
  DateTime? _lastBackgroundTime;
  DateTime? _lastForegroundTime;
  Duration _totalTimeOutOfApp = Duration.zero;
  final List<DateTime> _appExitTimes = [];
  final List<DateTime> _appReturnTimes = [];

  /// État actuel du focus
  bool get isAppInForeground => _isAppInForeground;
  DateTime? get lastBackgroundTime => _lastBackgroundTime;
  Duration get totalTimeOutOfApp => _totalTimeOutOfApp;
  List<DateTime> get appExitTimes => List.unmodifiable(_appExitTimes);
  List<DateTime> get appReturnTimes => List.unmodifiable(_appReturnTimes);

  /// Marquer l'app comme mise en arrière-plan
  void markAppBackground() {
    if (_isAppInForeground) {
      _isAppInForeground = false;
      _lastBackgroundTime = DateTime.now();
      _appExitTimes.add(_lastBackgroundTime!);
      
      debugPrint('App mise en arrière-plan à ${_lastBackgroundTime!}');
      notifyListeners();
    }
  }

  /// Marquer l'app comme remise au premier plan
  void markAppForeground() {
    if (!_isAppInForeground && _lastBackgroundTime != null) {
      _isAppInForeground = true;
      _lastForegroundTime = DateTime.now();
      _appReturnTimes.add(_lastForegroundTime!);
      
      final timeOut = _lastForegroundTime!.difference(_lastBackgroundTime!);
      _totalTimeOutOfApp += timeOut;
      
      debugPrint('App remise au premier plan après ${timeOut.inSeconds}s');
      notifyListeners();
    }
  }

  /// Valider l'intégrité du focus pour une session
  bool validateFocusIntegrity({Duration? maxAllowedTimeOut}) {
    final maxTime = maxAllowedTimeOut ?? const Duration(seconds: 30);
    
    // Vérifier si l'app est actuellement en arrière-plan
    if (!_isAppInForeground && _lastBackgroundTime != null) {
      final currentTimeOut = DateTime.now().difference(_lastBackgroundTime!);
      if (currentTimeOut > maxTime) {
        debugPrint('Focus perdu: app en arrière-plan depuis ${currentTimeOut.inSeconds}s');
        return false;
      }
    }

    // Vérifier le temps total passé hors de l'app
    if (_totalTimeOutOfApp > maxTime) {
      debugPrint('Focus perdu: temps total hors app ${_totalTimeOutOfApp.inSeconds}s > ${maxTime.inSeconds}s');
      return false;
    }

    return true;
  }

  /// Calculer la récompense FT basée sur l'intégrité du focus
  int calculateFTReward({
    required Duration sessionDuration,
    required Duration actualDuration,
    required bool wasCompleted,
  }) {
    // Vérifier l'intégrité du focus
    if (!validateFocusIntegrity()) {
      return 0; // Pas de récompense si le focus est perdu
    }

    return PomodoroSession.calculateFTEarned(
      sessionDuration: sessionDuration,
      actualDuration: actualDuration,
      wasCompleted: wasCompleted,
      wasAppLeft: _appExitTimes.isNotEmpty,
      timeOutOfApp: _totalTimeOutOfApp,
    );
  }

  /// Réinitialiser le tracker pour une nouvelle session
  void reset() {
    _isAppInForeground = true;
    _lastBackgroundTime = null;
    _lastForegroundTime = null;
    _totalTimeOutOfApp = Duration.zero;
    _appExitTimes.clear();
    _appReturnTimes.clear();
    
    debugPrint('FocusTracker réinitialisé');
    notifyListeners();
  }

  /// Obtenir les statistiques de focus
  Map<String, dynamic> getFocusStatistics() {
    return {
      'isAppInForeground': _isAppInForeground,
      'totalTimeOutOfApp': _totalTimeOutOfApp.inSeconds,
      'exitCount': _appExitTimes.length,
      'returnCount': _appReturnTimes.length,
      'lastBackgroundTime': _lastBackgroundTime?.toIso8601String(),
      'lastForegroundTime': _lastForegroundTime?.toIso8601String(),
      'integrityValid': validateFocusIntegrity(),
    };
  }
}