import 'package:hive/hive.dart';

part 'history_item.g.dart'; // Hive generator가 생성할 파일입니다.

@HiveType(typeId: 0)
class HistoryItem extends HiveObject{
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime dateVisited;

  HistoryItem({required this.url,required this.title ,required this.dateVisited});
}
