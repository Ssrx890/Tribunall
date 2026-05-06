import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show MobileAds;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config/monetization_config.dart';
import 'models/banco.dart';
import 'models/bancos.dart';
import 'state/app_state.dart';

Future<AppState> loadInitialAppState({bool enableMonetization = true}) async {
  final banco = await Banco.cargar();
  final bancosData = await Bancos.cargar();
  final prefs = await SharedPreferences.getInstance();
  final esPremium = prefs.getBool('es_premium') ?? false;
  final tutorialVisto = prefs.getBool('tutorial_visto') ?? false;
  final sonidoActivo = prefs.getBool('sonido_activo') ?? true;
  final vibracionActiva = prefs.getBool('vibracion_activo') ?? true;

  return AppState(
    banco: banco,
    bancos: bancosData,
    esPremiumInicial: esPremium,
    tutorialVistoInicial: tutorialVisto,
    sonidoActivoInicial: sonidoActivo,
    vibracionActivaInicial: vibracionActiva,
    enableMonetization: enableMonetization,
  );
}

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  if (MonetizationConfig.adsEnabled) {
    await MobileAds.instance.initialize();
  }

  try {
    final appState = await loadInitialAppState();
    runApp(
      TribunalAppScope(
        appState: appState,
        child: const ElTribunalApp(),
      ),
    );
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'tribunall.bootstrap',
        context: ErrorDescription('while bootstrapping the application'),
      ),
    );
    runApp(TribunalStartupErrorApp(error: error));
  }
}