// pattern_result.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/component/bottom_banner_ad.dart';

class PatternResult extends StatelessWidget {
  final List<dynamic> results;
  final String userPattern;
  final String market;
  final String lang;

  PatternResult(
      {Key? key,
        required this.results,
        required this.userPattern,
        required this.market,
        required this.lang})
      : super(key: key);

  String createResultUrl(String code, String date) {
    return 'https://www.similarchart.com/stock_info/?code=$code&lang=$lang';
  }

  @override
  Widget build(BuildContext context) {
    var userImage = base64Decode(userPattern);

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: Text('패턴검색 결과', style: TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.secondaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // 현재 PatternResult 화면 닫기
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                color: Colors.white, // Set a background color that suits the image
                child: Image.memory(
                  userImage,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              results.isEmpty ? "비슷한 패턴을 찾지 못했습니다" : "원하는 패턴을 선택하세요",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 6,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: results.length,
              itemBuilder: (BuildContext context, int index) {
                var result = results[index];
                var image = base64Decode(result['img']);
                return InkWell(
                  onTap: () {
                    String url = createResultUrl(result['code'], result['date']);
                    Navigator.pop(context, url);
                  },
                  child: Ink.image(
                    image: MemoryImage(image),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                PatternResultManager.clearData();
              },
              child: Text('다시 검색하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: AppColors.textColor,
              ),
            ),
          ),
          const BottomBannerAd(),
        ],
      ),
    );
  }
}

// pattern_result_manager.dart
class PatternResultManager {
  static List<dynamic> results = [];
  static String userPattern = '';
  static String market = '';
  static String lang = '';
  static bool isScreenDisplayed = false;

  static void initializePatternResult(
      {required List<dynamic> res,
        required String pattern,
        required String mkt,
        required String language}) {
    results = res;
    userPattern = pattern;
    market = mkt;
    lang = language;
    isScreenDisplayed = true;
  }

  static void clearData() {
    results.clear();
    userPattern = '';
    market = '';
    lang = '';
    isScreenDisplayed = false;
  }

  static bool isResultExist() {
    return isScreenDisplayed;
  }

  static void showPatternResult(BuildContext context) async {
    if (!isScreenDisplayed) {
      return;
    }

    String? url = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatternResult(
            results: results,
            userPattern: userPattern,
            market: market,
            lang: lang),
      ),
    );

    if (url != null) {
      Navigator.pop(context, url);
    }
  }
}
