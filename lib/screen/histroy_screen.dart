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
          return ListView.separated(
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final historyItem = box.getAt(index);
              return ListTile(
                horizontalTitleGap: 10,
                title: Text(historyItem!.title,
                    style: TextStyle(color: AppColors.textColor)),
                subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(historyItem.dateVisited),
                    style: TextStyle(color: AppColors.textColor)),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: AppColors.secondaryColor), // X 모양 아이콘
                  onPressed: () async {
                    // Hive Box에서 해당 항목 삭제
                    await box.deleteAt(index);
                    setState(() {});
                  },
                ),
              );
            },
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey, // 구분선의 색상을 지정하세요.
              height: 1,
            ),
          );
        },
      ),
    );
  }
}
