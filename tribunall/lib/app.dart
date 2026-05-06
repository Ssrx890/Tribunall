import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/nivel_juego.dart';
import 'screens/pantalla_acusados.dart';
import 'state/app_state.dart';
import 'theme/app_theme_data.dart';

class TribunalAppScope extends StatelessWidget {
  final AppState appState;
  final Widget child;

  const TribunalAppScope({
    super.key,
    required this.appState,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: child,
    );
  }
}

class ElTribunalApp extends StatelessWidget {
  const ElTribunalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final nivel = context.select<AppState, NivelJuego>((s) => s.nivel);
    final th = AppThemeData.forNivel(nivel);
    return MaterialApp(
      title: 'El Tribunal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: th.fondo,
        colorScheme: ColorScheme.dark(
          primary: th.accent,
          secondary: th.accent2,
          surface: th.superficie,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Lato',
              bodyColor: th.textoPrim,
              displayColor: th.textoPrim,
            ),
      ),
      home: const PantallaAcusados(),
    );
  }
}

class TribunalStartupErrorApp extends StatelessWidget {
  final Object error;

  const TribunalStartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F0E1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo iniciar El Tribunal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF9B91C4),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}