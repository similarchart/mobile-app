import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/colors.dart';
import '../model/history_item.dart';

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
                title: Text(historyItem!.url,
                    style: TextStyle(color: AppColors.textColor)),
                subtitle: Text(historyItem.dateVisited.toString(),
                    style: TextStyle(color: AppColors.textColor)),
              );
            },
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey, // 구분선의 색상을 지정하세요.
              height: 1, // 구분선의 높이를 지정하세요. 실제 선의 두께와는 다를 수 있습니다.
            ),
          );
        },
      ),
    );
  }
}
