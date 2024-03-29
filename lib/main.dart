import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:web_view/screen/home_screen.dart';
import 'model/history_item.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(HistoryItemAdapter());
  await Hive.openBox<HistoryItem>('history');

  runApp(
    MaterialApp(
      home: HomeScreen(),
    ),
  );
}