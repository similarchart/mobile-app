import 'package:hive/hive.dart';

part 'history_item.g.dart'; // Hive generator가 생성할 파일입니다.

@HiveType(typeId: 0)
class HistoryItem {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final DateTime dateVisited;

  @HiveField(2)
  bool isFav;

  HistoryItem({required this.url, required this.dateVisited, required this.isFav});
}
