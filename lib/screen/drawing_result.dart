import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_view/constants/colors.dart';

class DrawingResult extends StatelessWidget {
  final List<dynamic> results;
  final String userDrawing;
  final String market;
  final String size;
  final String lang;

  DrawingResult(
      {Key? key,
      required this.results,
      required this.userDrawing,
      required this.market,
      required this.size,
      required this.lang})
      : super(key: key);

  String createResultUrl(String code, String date) {
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
            // 두 번째 pop을 추가하여 다이얼로그까지 닫기
            Navigator.of(context).pop(); // 현재 DrawingResult 화면 닫기
            Navigator.of(context).pop(); // 최초 다이얼로그 화면 닫기
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
                    String url =
                        createResultUrl(result['code'], result['date']);
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
                DrawingResultManager.clearData();
              },
              child: Text('다시 검색하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: AppColors.textColor,
              ),
            ),
          ),
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
  static String lang = '';
  static bool isScreenDisplayed = false;

  static void initializeDrawingResult(
      {required List<dynamic> res,
      required String drawing,
      required String mkt,
      required String sz,
      required String language}) async {
    results = res;
    userDrawing = drawing;
    market = mkt;
    size = sz;
    lang = language;
    isScreenDisplayed = true;
  }

  static void clearData() {
    results.clear();
    userDrawing = '';
    market = '';
    size = '';
    lang = '';
    isScreenDisplayed = false;
  }

  static bool isResultExist() {
    return isScreenDisplayed;
  }

  static void showDrawingResult(BuildContext context) async {
    if (!isScreenDisplayed) {
      return;
    }

    String? url = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingResult(
            results: results,
            userDrawing: userDrawing,
            market: market,
            size: size,
            lang: lang),
      ),
    );

    if (url != null) {
      Navigator.pop(context, url);
    }
  }
}
