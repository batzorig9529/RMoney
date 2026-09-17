import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads consent-aware interstitial ads for natural workflow breaks.
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
  bool _initialized = false;
  bool _privacyOptionsRequired = false;
  DateTime? _lastShown;

  final privacyOptionsRequiredNotifier = ValueNotifier<bool>(false);
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  Future<void> initialize() async {
    final completer = Completer<void>();
    final consentInformation = ConsentInformation.instance;

    Future<void> finish() async {
      _privacyOptionsRequired =
          await consentInformation.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
      privacyOptionsRequiredNotifier.value = _privacyOptionsRequired;
      if (await consentInformation.canRequestAds()) {
        await MobileAds.instance.initialize();
        _initialized = true;
        _load();
      }
      if (!completer.isCompleted) completer.complete();
    }

    consentInformation.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) => finish());
      },
      (_) => finish(),
    );
    // Consent/network failures must never prevent the finance tracker from
    // opening. A late callback can still initialize ads after the UI starts.
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  Future<void> showPrivacyOptions() async {
    if (!_privacyOptionsRequired) return;
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) async {
      if (!_initialized && await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        _initialized = true;
        _load();
      }
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  void _load() {
    if (!_initialized || _loading || _ad != null) return;
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
