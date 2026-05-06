import 'dart:io';

import 'package:flutter/foundation.dart';

class MonetizationConfig {
  static const String productPicanteId = 'modo_picante_v1';

  /// Ads only run in release builds. In debug/profile (emulator, flutter run)
  /// the AdMob WebView renderer crashes on emulators without GPU support.
  static bool get adsEnabled => kReleaseMode && (Platform.isAndroid || Platform.isIOS);

  static const bool iapEnabled = false;

  static bool get hasPicanteProduct =>
      iapEnabled && productPicanteId.trim().isNotEmpty;

  static String get bannerAdId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    return 'ca-app-pub-3940256099942544/2934735716';
  }

  static String get interstitialAdId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    return 'ca-app-pub-3940256099942544/4411468910';
  }

  static String get rewardedAdId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    return 'ca-app-pub-3940256099942544/1712485313';
  }
}