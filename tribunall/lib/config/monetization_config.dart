import 'dart:io';

class MonetizationConfig {
  static const String productPicanteId = 'modo_picante_v1';

  static const bool adsEnabled = true;
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