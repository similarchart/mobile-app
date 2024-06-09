import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/component/bottom_banner_ad.dart';
import 'package:web_view/screen/pattern_search/pattern_board.dart';

import '../../services/preferences.dart';

class PatternResult extends StatelessWidget {
  final List<dynamic> results;
  final String userPattern;
  final String market;

  const PatternResult(
      {super.key,
        required this.results,
        required this.userPattern,
        required this.market});

  String createResultUrl(String code, String date, String lang) {
    return 'https://www.similarchart.com/pattern_search/?code=$code&base_date=$date&market=$market&lang=$lang';
  }

  @override
  Widget build(BuildContext context) {
    var userImage = base64Decode(userPattern);

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: const Text('패턴검색 결과', style: TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.secondaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
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
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 6,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: results.length,
              itemBuilder: (BuildContext context, int index) {
                var result = results[index];
                var image = base64Decode(result['img']);
                return InkWell(
                  onTap: () async {
                    String lang = await LanguagePreference.getLanguageSetting();
                    String url = createResultUrl(result['code'], result['date'], lang);
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
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                PatternResultManager.clearData();

                double width = min(MediaQuery.of(context).size.height,
                    MediaQuery.of(context).size.width);
                double height = MediaQuery.of(context).size.height * 0.75;

                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    return Dialog(
                      insetPadding: const EdgeInsets.all(0),
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: PatternBoard(
                        ),
                      ),
                    );
                  },
                );
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
  static bool isScreenDisplayed = false;

  static void initializePatternResult(
      {required List<dynamic> res,
        required String pattern,
        required String mkt}) {
    results = res;
    userPattern = pattern;
    market = mkt;
    isScreenDisplayed = true;
  }

  static void clearData() {
    results.clear();
    userPattern = '';
    market = '';
    isScreenDisplayed = false;
  }

  static bool isResultExist() {
    return isScreenDisplayed;
  }

  static Future<String?> showPatternResult(BuildContext context) async {
    if (!isScreenDisplayed) {
      return null;
    }

    return await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PatternResult(
          results: results,
          userPattern: userPattern,
          market: market,
        ),
      ),
    );
  }
}