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
        title: const Text('방문기록', style: TextStyle(color: AppColors.textColor)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('삭제 확인'),
                    content: const Text('방문기록을 모두 지우시겠습니까?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Yes'),
                        onPressed: () async {
                          await historyBox.clear();
                          Navigator.of(context).pop();
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
          final reversedList = box.values.toList().reversed.take(100).toList();
          return ListView.builder(
            itemCount: reversedList.length,
            itemBuilder: (context, index) {
              final historyItem = reversedList.elementAt(index);
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  border: Border(bottom: BorderSide(color: AppColors.secondaryColor, width: 1)),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context, historyItem.url);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(historyItem.title,
                                  style: TextStyle(fontSize: 14, color: AppColors.textColor)),
                              Text(
                                  DateFormat('yyyy-MM-dd HH:mm:ss').format(historyItem.dateVisited),
                                  style: TextStyle(fontSize: 11, color: AppColors.textColor)
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          iconSize: 20,
                          icon: Icon(Icons.close, color: AppColors.secondaryColor),
                          onPressed: () async {
                            final realIndex = box.values.length - 1 - index;
                            await box.deleteAt(realIndex);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
