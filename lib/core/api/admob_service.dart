import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Ad Unit IDs
  static const String _rewardedAdUnitId = 'ca-app-pub-3869216132353672/7539598452';
  static const String _interstitialAdUnitId = 'ca-app-pub-3869216132353672/8572606389';
  static const String _nativeAdUnitId = 'ca-app-pub-3869216132353672/8716948758';

  // Test Ad Unit IDs (for development)
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Ad instances
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  NativeAd? _nativeAd;

  // Ad loading states
  bool _isRewardedAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isNativeAdLoaded = false;

  // Getters
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isNativeAdLoaded => _isNativeAdLoaded;

  // Initialize AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Get appropriate ad unit ID based on platform and debug mode
  String _getAdUnitId(String productionId, String testId) {
    // In production, use production IDs
    // In debug mode, use test IDs
    return kDebugMode ? testId : productionId;
  }

  // Load Rewarded Ad
  Future<void> loadRewardedAd() async {
    try {
      await _rewardedAd?.dispose();
      _rewardedAd = null;

      await RewardedAd.load(
        adUnitId: _getAdUnitId(_rewardedAdUnitId, _testRewardedAdUnitId),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            print('Rewarded ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdLoaded = false;
            print('Rewarded ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
      _isRewardedAdLoaded = false;
    }
  }

  // Show Rewarded Ad
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null || !_isRewardedAdLoaded) {
      print('Rewarded ad not loaded');
      return false;
    }

    try {
      bool adShown = false;
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          adShown = true;
        },
      );
      _isRewardedAdLoaded = false;
      return adShown;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  // Load Interstitial Ad
  Future<void> loadInterstitialAd() async {
    try {
      await _interstitialAd?.dispose();
      _interstitialAd = null;

      await InterstitialAd.load(
        adUnitId: _getAdUnitId(_interstitialAdUnitId, _testInterstitialAdUnitId),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            print('Interstitial ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isInterstitialAdLoaded = false;
            print('Interstitial ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
      _isInterstitialAdLoaded = false;
    }
  }

  // Show Interstitial Ad
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null || !_isInterstitialAdLoaded) {
      print('Interstitial ad not loaded');
      return false;
    }

    try {
      _interstitialAd!.show();
      _isInterstitialAdLoaded = false;
      return true;
    } catch (e) {
      print('Error showing interstitial ad: $e');
      return false;
    }
  }

  // Load Native Ad
  Future<void> loadNativeAd() async {
    try {
      await _nativeAd?.dispose();
      _nativeAd = null;

      _nativeAd = NativeAd(
        adUnitId: _getAdUnitId(_nativeAdUnitId, _testNativeAdUnitId),
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            _isNativeAdLoaded = true;
            print('Native ad loaded successfully');
          },
          onAdFailedToLoad: (ad, error) {
            _isNativeAdLoaded = false;
            print('Native ad failed to load: $error');
          },
        ),
      );

      await _nativeAd!.load();
    } catch (e) {
      print('Error loading native ad: $e');
      _isNativeAdLoaded = false;
    }
  }

  // Get Native Ad Widget
  Widget? getNativeAdWidget() {
    if (_nativeAd == null || !_isNativeAdLoaded) {
      return null;
    }
    return _nativeAd!;
  }

  // Preload all ads
  Future<void> preloadAllAds() async {
    await Future.wait([
      loadRewardedAd(),
      loadInterstitialAd(),
      loadNativeAd(),
    ]);
  }

  // Dispose all ads
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _nativeAd?.dispose();
    _isRewardedAdLoaded = false;
    _isInterstitialAdLoaded = false;
    _isNativeAdLoaded = false;
  }
}
