import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'services/services.dart';
import 'modules/pedometer/pedometer.dart';
import 'screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurer l'orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const FocusWorldApp());
}

class FocusWorldApp extends StatelessWidget {
  const FocusWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameService>(
          create: (_) => GameService.instance,
        ),
        ChangeNotifierProvider<TimeFragmentService>(
          create: (_) => TimeFragmentService.instance,
        ),
        ChangeNotifierProvider<StepCounter>(
          create: (_) => StepCounter.instance,
        ),
      ],
      child: MaterialApp(
        title: 'Focus World',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const AppLifecycleWrapper(
          child: HomeScreen(),
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Wrapper pour gérer le cycle de vie de l'application
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Notifier le timer Pomodoro du changement d'état si nécessaire
    // final pomodoroTimer = context.read<GameService>().fragmentService;
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App reprise au premier plan');
        break;
      case AppLifecycleState.paused:
        debugPrint('App mise en arrière-plan');
        break;
      case AppLifecycleState.detached:
        debugPrint('App fermée');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App cachée');
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
