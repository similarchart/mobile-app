import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/component/bottom_banner_ad.dart';

import '../../services/preferences.dart';
import 'drawing_board.dart';

class DrawingResult extends StatelessWidget {
  final List<dynamic> results;
  final String userDrawing;
  final String market;
  final String size;

  void initState() {

  }

  DrawingResult(
      {Key? key,
      required this.results,
      required this.userDrawing,
      required this.market,
      required this.size})
      : super(key: key);

  String createResultUrl(String code, String date, String lang) {
    return 'https://www.similarchart.com/result/?code=$code&base_date=$date&market=$market&day_num=$size&lang=$lang';
  }

  @override
  Widget build(BuildContext context) {
    var userImage = base64Decode(userDrawing);

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: Text('드로잉검색 결과', style: TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.secondaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
                color:
                    Colors.white, // Set a background color that suits the image
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
              results.isEmpty ? "비슷한 차트를 찾지 못했습니다" : "원하는 차트를 선택하세요",
              style: TextStyle(
                fontSize: 15,
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
                  onTap: () async {
                    String lang = await LanguagePreference.getLanguageSetting();
                    String url =
                        createResultUrl(result['code'], result['date'], lang);
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
                DrawingResultManager.clearData();

                double width = min(
                    MediaQuery
                        .of(context)
                        .size
                        .height, MediaQuery
                    .of(context)
                    .size
                    .width);
                double appBarHeight = AppBar().preferredSize.height;
                double adHeight = 60;
                double height = width + appBarHeight + adHeight;

                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    return Dialog(
                      insetPadding: const EdgeInsets.all(0),
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: DrawingBoard(
                          screenHeight: height - appBarHeight,
                        ),
                      ),
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: AppColors.textColor,
              ),
              child: const Text('다시 검색하기'),
            ),
          ),
          const BottomBannerAd(),
        ],
      ),
    );
  }
}

// drawing_search_manager.dart
class DrawingResultManager {
  static List<dynamic> results = [];
  static String userDrawing = '';
  static String market = '';
  static String size = '';
  static bool isScreenDisplayed = false;

  static void initializeDrawingResult(
      {required List<dynamic> res,
      required String drawing,
      required String mkt,
      required String sz}) async {
    results = res;
    userDrawing = drawing;
    market = mkt;
    size = sz;
    isScreenDisplayed = true;
  }

  static void clearData() {
    results.clear();
    userDrawing = '';
    market = '';
    size = '';
    isScreenDisplayed = false;
  }

  static bool isResultExist() {
    return isScreenDisplayed;
  }

  static Future<String?> showDrawingResult(BuildContext context) async {
    if (!isScreenDisplayed) {
      return null;
    }

    return await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingResult(
          results: results,
          userDrawing: userDrawing,
          market: market,
          size: size,
        ),
      ),
    );
  }
}
