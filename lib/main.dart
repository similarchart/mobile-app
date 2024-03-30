import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/screen/home_screen.dart';
import 'model/history_item.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(HistoryItemAdapter());
  Hive.registerAdapter(RecentItemAdapter());
  await Hive.openBox<HistoryItem>('history');
  await Hive.openBox<RecentItem>('recent');

  runApp(
    MaterialApp(
      home: HomeScreen(),
    ),
  );
}