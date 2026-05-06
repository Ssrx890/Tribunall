import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/monetization_config.dart';
import '../models/banco.dart';
import '../models/nivel_juego.dart';

class AppState extends ChangeNotifier {
  final Banco banco;
  final bool _enableMonetization;
  bool _esPremium;
  int _contadorJuicios = 0;
  int _tiempoConfigurado = 20;
  final List<String> _acusados = [];
  NivelJuego _nivel = NivelJuego.normal;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _iapSub;
  bool _iapDisponible = false;
  bool _cargandoPago = false;

  BannerAd? bannerAd;
  bool bannerCargado = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  AppState({
    required this.banco,
    required bool esPremiumInicial,
    bool enableMonetization = true,
  })  : _esPremium = esPremiumInicial,
        _enableMonetization = enableMonetization {
    if (!_enableMonetization) return;

    if (MonetizationConfig.iapEnabled) {
      _initIAP();
    }

    if (MonetizationConfig.adsEnabled) {
      _cargarInterstitial();
      _cargarRewarded();
      if (!_esPremium) _cargarBanner();
    }
  }

  bool get esPremium => _esPremium;
  bool get cargandoPago => _cargandoPago;
  bool get iapDisponible => _iapDisponible;
  int get contadorJuicios => _contadorJuicios;
  int get tiempoConfigurado => _tiempoConfigurado;
  List<String> get acusados => List.unmodifiable(_acusados);
  NivelJuego get nivel => _nivel;
  bool get esPicante => _nivel == NivelJuego.picante;
  bool get esIntermedio => _nivel == NivelJuego.intermedio;
  bool get anunciosActivos =>
      _enableMonetization && MonetizationConfig.adsEnabled && !_esPremium;
  bool get compraPicanteDisponible =>
      _enableMonetization && MonetizationConfig.hasPicanteProduct;
  bool get puedeDesbloquearIntermedio => esPremium || anunciosActivos;

  void setTiempo(int t) {
    _tiempoConfigurado = t;
    notifyListeners();
  }

  void agregarAcusado(String nombre) {
    final trimmed = nombre.trim();
    if (trimmed.isEmpty || trimmed.length > 50) return;
    _acusados.add(trimmed);
    notifyListeners();
  }

  void removerAcusado(int index) {
    _acusados.removeAt(index);
    notifyListeners();
  }

  void setNivel(NivelJuego n) {
    _nivel = n;
    notifyListeners();
  }

  void incrementarContador() {
    _contadorJuicios++;
    notifyListeners();
  }

  Future<void> _initIAP() async {
    _iapDisponible = await _iap.isAvailable();
    if (!_iapDisponible) {
      notifyListeners();
      return;
    }
    _iapSub = _iap.purchaseStream.listen(_onPurchaseUpdate);
    notifyListeners();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != MonetizationConfig.productPicanteId) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _cargandoPago = true;
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _setPremium(true);
          if (purchase.pendingCompletePurchase) {
            unawaited(_iap.completePurchase(purchase));
          }
          break;
        case PurchaseStatus.canceled:
        case PurchaseStatus.error:
          _cargandoPago = false;
          notifyListeners();
          break;
      }
    }
  }

  Future<void> _setPremium(bool value) async {
    _esPremium = value;
    _cargandoPago = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('es_premium', value);
    } catch (e) {
      debugPrint('Error al guardar estado premium: $e');
    }
    if (value) {
      bannerAd?.dispose();
      bannerAd = null;
      bannerCargado = false;
    } else if (anunciosActivos && bannerAd == null) {
      _cargarBanner();
    }
    notifyListeners();
  }

  Future<void> comprarPicante() async {
    if (!compraPicanteDisponible || !_iapDisponible) return;

    _cargandoPago = true;
    notifyListeners();

    final response = await _iap.queryProductDetails({
      MonetizationConfig.productPicanteId,
    });

    if (response.error != null || response.productDetails.isEmpty) {
      _cargandoPago = false;
      notifyListeners();
      return;
    }

    final param = PurchaseParam(productDetails: response.productDetails.first);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restaurarCompras() async {
    if (!compraPicanteDisponible || !_iapDisponible) return;

    _cargandoPago = true;
    notifyListeners();

    try {
      await _iap.restorePurchases();
    } finally {
      if (!_esPremium) {
        _cargandoPago = false;
        notifyListeners();
      }
    }
  }

  void _cargarBanner() {
    if (!anunciosActivos) return;

    bannerAd = BannerAd(
      adUnitId: MonetizationConfig.bannerAdId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          bannerCargado = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          bannerAd = null;
          bannerCargado = false;
          notifyListeners();
        },
      ),
    )..load();
  }

  void _cargarInterstitial() {
    if (!anunciosActivos && !_esPremium) return;

    InterstitialAd.load(
      adUnitId: MonetizationConfig.interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  void _cargarRewarded() {
    if (!_enableMonetization || !MonetizationConfig.adsEnabled) return;

    RewardedAd.load(
      adUnitId: MonetizationConfig.rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  void mostrarInterstitial() {
    if (!anunciosActivos || _interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _cargarInterstitial();
      },
    );
    _interstitialAd!.show();
  }

  Future<bool> mostrarRewardedYEsperar() async {
    if (esPremium) return true;
    if (!_enableMonetization || !MonetizationConfig.adsEnabled) return false;

    if (_rewardedAd == null) {
      final completer = Completer<bool>();
      RewardedAd.load(
        adUnitId: MonetizationConfig.rewardedAdId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load on demand: $error');
            completer.complete(false);
          },
        ),
      );
      final loaded = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      if (!loaded) return false;
    }

    final completer = Completer<bool>();
    var rewarded = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _cargarRewarded();
        completer.complete(rewarded);
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (_, _) {
        rewarded = true;
      },
    );
    return completer.future;
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}