import 'package:hive/hive.dart';

part 'recent_item.g.dart'; // Hive generator가 생성할 파일입니다.

@HiveType(typeId: 1)
class RecentItem extends HiveObject {
  @HiveField(0)
  final String code;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime dateVisited;

  @HiveField(3)
  final String url;

  @HiveField(4)
  bool isFav;

  RecentItem({
    required this.code,
    required this.name,
    required this.dateVisited,
    required this.url,
    this.isFav = false,
  });
}
