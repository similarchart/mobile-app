import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                          'assets/logo_1024.png',
                          width: 80),
                        SizedBox(height: 10),
                        const Text('Similar Chart Finder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                        const Text('주식매매를 위한 필수 보조지표',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 20),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('차트 로드중... ',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            SizedBox(width: 20),
                            SizedBox(
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
