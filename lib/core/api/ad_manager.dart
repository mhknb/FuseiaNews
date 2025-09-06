import 'package:flutter/material.dart';
import 'admob_service.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  final AdMobService _adMobService = AdMobService();
  int _interstitialCounter = 0;
  int _rewardedCounter = 0;

  // Interstitial ad göster (her 3. kategori değişiminde)
  Future<void> showInterstitialAdOnCategoryChange() async {
    _interstitialCounter++;
    if (_interstitialCounter >= 3) {
      await _adMobService.loadInterstitialAd();
      await _adMobService.showInterstitialAd();
      _interstitialCounter = 0;
    }
  }

  // Interstitial ad göster (her 5. refresh'te)
  Future<void> showInterstitialAdOnRefresh() async {
    _rewardedCounter++;
    if (_rewardedCounter >= 5) {
      await _adMobService.loadInterstitialAd();
      await _adMobService.showInterstitialAd();
      _rewardedCounter = 0;
    }
  }

  // Rewarded ad göster (premium özellikler için)
  Future<bool> showRewardedAdForPremiumFeature() async {
    await _adMobService.loadRewardedAd();
    return await _adMobService.showRewardedAd();
  }

  // Uygulama başlangıcında tüm reklamları yükle
  Future<void> preloadAds() async {
    await _adMobService.preloadAllAds();
  }

  // Reklam servisini temizle
  void dispose() {
    _adMobService.dispose();
  }
}
