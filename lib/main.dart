import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/screen/home_screen.dart';
import 'model/history_item.dart';
import 'package:web_view/services/background_tasks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// RouteObserver 객체 생성
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureBackgroundFetch();

  MobileAds.instance.initialize();
  
  // Hive 초기화 및 박스 열기
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryItemAdapter());
  Hive.registerAdapter(RecentItemAdapter());
  await Hive.openBox<HistoryItem>('history');
  await Hive.openBox<RecentItem>('recent');

  // 앱 실행
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(),
    navigatorObservers: [routeObserver], // RouteObserver 추가
  ));
}
