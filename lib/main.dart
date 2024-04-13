import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/screen/home_screen.dart';
import 'model/history_item.dart';
import 'package:web_view/services/background_tasks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureBackgroundFetch();

  // Hive 초기화 및 박스 열기
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryItemAdapter());
  Hive.registerAdapter(RecentItemAdapter());
  await Hive.openBox<HistoryItem>('history');
  await Hive.openBox<RecentItem>('recent');

  // 앱 실행
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(),
  ));
}
