import 'dart:io';

import 'package:flutter/foundation.dart';

class MonetizationConfig {
  static const String productPicanteId = 'modo_picante_v1';

  /// Ads only run in release builds. In debug/profile (emulator, flutter run)
  /// the AdMob WebView renderer crashes on emulators without GPU support.
  static bool get adsEnabled =>
      !kIsWeb && kReleaseMode && (Platform.isAndroid || Platform.isIOS);

  static const bool iapEnabled = true;

  static bool get hasPicanteProduct =>
      iapEnabled && productPicanteId.trim().isNotEmpty;

  static String get bannerAdId {
    if (Platform.isAndroid) return 'ca-app-pub-1676922798634610/4629393187';
    return 'ca-app-pub-1676922798634610/4629393187';
  }

  static String get interstitialAdId {
    if (Platform.isAndroid) return 'ca-app-pub-1676922798634610/9109967787';
    return 'ca-app-pub-1676922798634610/9109967787';
  }

  static String get rewardedAdId {
    if (Platform.isAndroid) return 'ca-app-pub-1676922798634610/8048167556';
    return 'ca-app-pub-1676922798634610/8048167556';
  }
}