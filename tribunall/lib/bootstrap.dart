import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  // Migrate es_premium from SharedPreferences to secure storage (one-time)
  const secureStorage = FlutterSecureStorage();
  bool esPremium;
  final legacyPremium = prefs.getBool('es_premium');
  if (legacyPremium != null) {
    esPremium = legacyPremium;
    await secureStorage.write(key: 'es_premium', value: legacyPremium.toString());
    await prefs.remove('es_premium');
  } else {
    final stored = await secureStorage.read(key: 'es_premium');
    esPremium = stored == 'true';
  }

  final tutorialVisto = prefs.getBool('tutorial_visto') ?? false;
  final sonidoActivo = prefs.getBool('sonido_activo') ?? true;
  final musicaActiva = prefs.getBool('musica_activa') ?? true;
  final vibracionActiva = prefs.getBool('vibracion_activa') ?? true;

  return AppState(
    banco: banco,
    bancos: bancosData,
    esPremiumInicial: esPremium,
    tutorialVistoInicial: tutorialVisto,
    sonidoActivoInicial: sonidoActivo,
    musicaActivaInicial: musicaActiva,
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
    // Uncomment and replace with your device ID to test ads on a real device.
    // Get your ID from logcat: "Use RequestConfiguration.Builder().setTestDeviceIds"
    // MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(testDeviceIds: ['YOUR_TEST_DEVICE_ID']),
    // );
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