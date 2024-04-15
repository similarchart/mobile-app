import 'package:flutter/material.dart';
import 'package:web_view/constants/colors.dart';

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
              Container(
                height: 60, // 상단 바의 높이
                color: AppColors.primaryColor, // 상단 바의 배경색
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                          'assets/logo_2.png',
                          width: 130),
                        SizedBox(height: 20),
                        const Text('Similar Chart Finder',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800)),
                        SizedBox(height: 20),
                        const Text('주식매매를 위한 필수 보조지표',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                        SizedBox(height: 100),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('차트 로드중... ',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                            SizedBox(width: 20),
                            SizedBox(
                              height: 20,
                              width: 20,
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
              Container(
                height: 60, // 하단 바의 높이
                color: AppColors.primaryColor, // 상단 바의 배경색
              ),
            ]
          ),
        ),
      ),
    );
  }
}
