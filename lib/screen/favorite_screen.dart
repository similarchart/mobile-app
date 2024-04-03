import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/services/language_preference.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    final Box<RecentItem> recentBox = Hive.box<RecentItem>('recent');

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: Text('종목기록', style: TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: ValueListenableBuilder(
        valueListenable: recentBox.listenable(),
        builder: (context, Box<RecentItem> box, _) {
          final items = box.values.toList();
          // isFav == true 인 항목들을 먼저 정렬합니다.
          final favItems = items.where((item) => item.isFav).toList()
            ..sort((a, b) => b.dateVisited.compareTo(a.dateVisited));
          // isFav == false 인 항목들을 나중에 정렬합니다.
          final notFavItems = items.where((item) => !item.isFav).toList()
            ..sort((a, b) => b.dateVisited.compareTo(a.dateVisited));
          // 두 리스트를 병합합니다.
          final sortedItems = favItems + notFavItems;

          return ListView.separated(
            itemCount: sortedItems.length,
            itemBuilder: (context, index) {
              final recentItem = sortedItems[index];
              return ListTile(
                horizontalTitleGap: 10,
                title: Text(recentItem.name,
                    style: TextStyle(color: AppColors.textColor)),
                subtitle: Text(recentItem.code,
                    style: TextStyle(color: AppColors.textColor)),
                leading: IconButton(
                  icon: Icon(
                    recentItem.isFav ? Icons.star : Icons.star_border,
                    color: AppColors.tertiaryColor,
                  ),
                  onPressed: () async {
                    recentItem.isFav = !recentItem.isFav;
                    // 변경사항을 Hive에 저장
                    await recentItem.save();
                  },
                ),
                onTap: () async {
                  String lang = await LanguagePreference.getLanguageSetting();
                  String nextUrl = "https://www.similarchart.com/stock_info/?code=${recentItem.code}&lang=${lang}";
                  Navigator.pop(context, nextUrl);
                },
              );
            },
            separatorBuilder: (context, index) => Divider(
              color: AppColors.secondaryColor,
              height: 1,
            ),
          );
        },
      ),
    );
  }
}
