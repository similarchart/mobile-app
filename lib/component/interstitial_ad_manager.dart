import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  // 인스턴스 생성 시 전면 광고 로드 시작
  InterstitialAdManager() {
    _loadInterstitialAd();
  }

  // 전면 광고 로드
  void _loadInterstitialAd() {
    final adUnitId = Platform.isIOS
        ? 'ca-app-pub-3940256099942544/4411468910' // iOS 전면 광고 단위 ID
        : 'ca-app-pub-3940256099942544/1033173712'; // 테스트용
    // : dotenv.env['ADMOB_INTERSTITIAL'] ?? 'ca-app-pub-3940256099942544/1033173712'; // 배포용

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            _loadInterstitialAd();
          }
        },
      ),
    );
  }

  // 임시 전면 커버 화면
  void _showCoverScreen(BuildContext context) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) {
        return const Scaffold(
          backgroundColor: Colors.black, // 검은색 배경
          body: Center(
            child: CircularProgressIndicator(color: Colors.white), // 로딩 표시
          ),
        );
      },
    ));
  }

// 광고가 닫히면 커버 화면 제거
  void _removeCoverScreen(BuildContext context) {
    Navigator.of(context).pop();
  }

// 전면 광고 관리 클래스 내 메서드 변경
  void showInterstitialAd(BuildContext context) {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _showCoverScreen(context); // 전면 광고 보여주기 전 커버 화면 표시

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        _removeCoverScreen(context); // 광고가 닫히면 커버 화면 제거
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        _removeCoverScreen(context); // 실패 시에도 커버 화면 제거
        ad.dispose();
        _loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // 리소스 해제
  void dispose() {
    _interstitialAd?.dispose();
  }
}
