import 'dart:convert';
import 'package:flutter/material.dart';

class DrawingResult extends StatelessWidget {
  final List<dynamic> results;
  final String userDrawing;
  final String market;
  final String size;
  final String lang;

  DrawingResult({Key? key, required this.results, required this.userDrawing, required this.market, required this.size, required this.lang}) : super(key: key);

  String createResultUrl(String code, String date) {
    return 'https://www.similarchart.com/result/?code=$code&base_date=$date&market=$market&day_num=$size&lang=$lang';
  }

  @override
  Widget build(BuildContext context) {
    var userImage = base64Decode(userDrawing);

    return Scaffold(
      appBar: AppBar(
        title: Text('드로잉검색 결과'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Center(
              child: Image.memory(
                userImage,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              "이미지를 클릭하시면 URL로 이동됩니다",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 5,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
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
        ],
      ),
    );
  }
}
