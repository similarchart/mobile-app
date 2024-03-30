import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/model/history_item.dart';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final Box<HistoryItem> historyBox = Hive.box<HistoryItem>('history');

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: Text('방문기록', style: TextStyle(color: AppColors.textColor)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('삭제 확인'),
                    content: Text('방문기록을 모두 지우시겠습니까?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop(); // 대화상자 닫기
                        },
                      ),
                      TextButton(
                        child: Text('Yes'),
                        onPressed: () async {
                          // Hive Box에서 해당 항목 삭제
                          historyBox.clear();
                          Navigator.of(context).pop(); // 대화상자 닫기
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        backgroundColor: AppColors.secondaryColor,
      ),
      body: ValueListenableBuilder(
        valueListenable: historyBox.listenable(),
        builder: (context, Box<HistoryItem> box, _) {
          final reversedList = box.values.toList().reversed; // 여기서 순서를 뒤집습니다.
          return ListView.separated(
            itemCount:
                reversedList.length, // itemCount를 reversedList의 길이로 설정합니다.
            itemBuilder: (context, index) {
              final historyItem =
                  reversedList.elementAt(index); // 인덱스로 아이템에 접근합니다.
              return ListTile(
                horizontalTitleGap: 10,
                title: Text(historyItem.title,
                    style: TextStyle(color: AppColors.textColor)),
                subtitle: Text(
                    DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(historyItem.dateVisited),
                    style: TextStyle(color: AppColors.textColor)),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: AppColors.secondaryColor),
                  onPressed: () async {
                    // reversedList에서의 실제 인덱스를 계산합니다.
                    final realIndex = box.values.length - 1 - index;
                    await box.deleteAt(realIndex); // 실제 인덱스를 사용하여 삭제합니다.
                    setState(() {});
                  },
                ),
                onTap: () {
                  Navigator.pop(context, historyItem.url);
                },
              );
            },
            separatorBuilder: (context, index) => Divider(
              color: AppColors.secondaryColor,
              height: 1,
            ),
          );
        },
      ),
    );
  }
}
