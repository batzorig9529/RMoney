import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads and shows interstitial ads on a timed interval.
/// Uses Google's public test ad unit IDs; swap in real ones before release.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _androidUnitId = 'ca-app-pub-4703508710013914/4017280320';
  // TODO: replace with the real iOS interstitial ad unit ID once created.
  static const _iosTestUnitId = 'ca-app-pub-3940256099942544/4411468910';

  static String get interstitialUnitId =>
      Platform.isIOS ? _iosTestUnitId : _androidUnitId;

  static const minInterval = Duration(minutes: 3);

  InterstitialAd? _ad;
  bool _loading = false;
  DateTime? _lastShown;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _load();
  }

  void _load() {
    if (_loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
          _ad = null;
        },
      ),
    );
  }

  /// Shows an interstitial if enough time has passed since the last one.
  /// No-op (and doesn't count as "shown") when no ad is ready yet.
  void maybeShow() {
    final ad = _ad;
    if (ad == null) {
      _load();
      return;
    }
    final now = DateTime.now();
    if (_lastShown != null && now.difference(_lastShown!) < minInterval) {
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _ad = null;
        _load();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _ad = null;
        _load();
      },
    );
    _lastShown = now;
    ad.show();
  }
}
