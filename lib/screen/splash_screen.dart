import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          fontFamily: "NotoSansKR"
      ),
      home: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                            AppLocalizations.of(context).translate('splash_img'),
                          width: 80),
                        const SizedBox(height: 10),
                        const Text('Similar Chart Finder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                        Text(AppLocalizations.of(context).translate('essential_indicators_for_trading'),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context).translate('loading_chart'),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 20),
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, // 인디케이터의 선 두께를 설정
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ]
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}
