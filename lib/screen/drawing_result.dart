import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

import '../services/preferences.dart'; // 언어 설정을 가져오는 서비스

class DrawingResult extends StatefulWidget {
  final String data;
  final String selectedMarket;
  final String selectedSize;

  const DrawingResult({
    super.key,
    required this.data,
    required this.selectedMarket,
    required this.selectedSize,
  });

  @override
  State<DrawingResult> createState() => _DrawingResultState();
}

class _DrawingResultState extends State<DrawingResult> {
  late List<dynamic> results;
  late String currentLang; // 현재 언어 설정을 저장할 변수
  Map<String, String> imageUrls = {}; // URL과 해당 URL의 이미지 링크 매핑

  @override
  void initState() {
    super.initState();
    initialize();
  }

  // 초기화 함수
  Future<void> initialize() async {
    currentLang = await LanguagePreference.getLanguageSetting(); // 언어 설정 불러오기
    parseData(); // 데이터 파싱 진행
  }

  void parseData() {
    results = jsonDecode(widget.data);
    fetchImages();
  }

  // 각 URL에서 이미지 URL을 가져오는 함수
  void fetchImages() async {
    for (var result in results) {
      String url = createResultUrl(result['code'], result['date'], widget.selectedMarket, widget.selectedSize);
      http.get(Uri.parse(url)).then((response) {
        dom.Document document = parser.parse(response.body);
        dom.Element? ogImage = document.querySelector('meta[property="og:image"]');
        if (ogImage != null && ogImage.attributes['content'] != null) {
          setState(() {
            imageUrls[url] = "https://www.similarchart.com"+ogImage.attributes['content']!;
            print("imageUrls :::${imageUrls[url]}");
          });
        }
      }).catchError((e) {
        print('Error fetching image URL: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Drawing URLs'),
        ),
        body: ListView.builder(
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            String url = imageUrls.keys.elementAt(index);
            String imageUrl = imageUrls[url]!;
            return ListTile(
              title: Image.network(imageUrl),
              onTap: () {
                // 이미지를 클릭했을 때의 동작을 여기에 정의
                print('url: $url');
                print('imageUrl: $imageUrl');
              },
            );
          },
        ),
      ),
    );
  }

  // URL 생성 함수
  String createResultUrl(String code, String date, String market, String size) {

    return 'https://www.similarchart.com/result/?code=$code&base_date=$date&market=$market&day_num=$size&lang=$currentLang';
  }
}
