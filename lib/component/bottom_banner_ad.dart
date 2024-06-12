import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:web_view/constants/colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_view/system/logger.dart';

const int adHeight = 60;

class BottomBannerAd extends StatefulWidget {
  const BottomBannerAd({super.key});

  @override
  State<BottomBannerAd> createState() => _BottomBannerAdState();
}

class _BottomBannerAdState extends State<BottomBannerAd> {
  BannerAd? banner;
  bool isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final adUnitId = Platform.isIOS
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'ca-app-pub-3940256099942544/6300978111'; // 테스트용
    // : dotenv.env['ADMOB_BOTTOM_BANNER'] ?? 'ca-app-pub-3940256099942544/6300978111'; // 배포용

    banner = BannerAd(
      size: AdSize.getInlineAdaptiveBannerAdSize(screenWidth.toInt(), adHeight),
      adUnitId: adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          Log.instance.e('Ad failed to load: $error');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    );

    banner!.load();
  }

  @override
  void dispose() {
    banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.primaryColor, // 광고가 로드되지 않았을 때 보여줄 기본 색상
      child: isAdLoaded
          ? AdWidget(ad: banner!)
          : SizedBox(), // 광고 로드되면 AdWidget을, 아니면 빈 상자
    );
  }
}
