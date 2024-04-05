import 'package:flutter/material.dart';
import 'package:web_view/constants/colors.dart';
import 'home_screen.dart'; // HomeScreen을 import 합니다.

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final HomeScreen homeScreen; // 멤버 변수로 선언

  @override
  void initState() {
    super.initState();
    homeScreen = HomeScreen(onLoaded: _onHomePageLoaded); // 인스턴스 초기화
    homeScreen.loadInitialUrl(); // 로딩 시작
  }

  void _onHomePageLoaded() {
    // 페이지 로딩이 끝나면 홈 화면으로 전환합니다.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => homeScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
                height: 65, // 상단 바의 높이
                color: AppColors.primaryColor, // 상단 바의 배경색
              ),
            ]
          ),
        ),
      ),
    );
  }
}
