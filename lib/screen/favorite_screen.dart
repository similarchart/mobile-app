import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/services/preferences.dart';

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
        title: Text('최근 본 종목', style: TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: ValueListenableBuilder(
        valueListenable: recentBox.listenable(),
        builder: (context, Box<RecentItem> box, _) {
          final items = box.values.toList();
          final favItems = items.where((item) => item.isFav).toList()
            ..sort((a, b) => b.dateVisited.compareTo(a.dateVisited));
          final notFavItems = items.where((item) => !item.isFav).toList()
            ..sort((a, b) => b.dateVisited.compareTo(a.dateVisited));
          final sortedItems = (favItems + notFavItems).take(100).toList();

          return ListView.builder(
            itemCount: sortedItems.length,
            itemBuilder: (context, index) {
              final recentItem = sortedItems[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  border: Border(bottom: BorderSide(color: AppColors.secondaryColor, width: 1)),
                ),
                child: InkWell(
                  onTap: () async {
                    String lang = await LanguagePreference.getLanguageSetting();
                    String nextUrl = "https://www.similarchart.com/stock_info/?code=${recentItem.code}&lang=${lang}";
                    Navigator.pop(context, nextUrl);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          icon: Icon(recentItem.isFav ? Icons.star : Icons.star_border,
                              color: AppColors.tertiaryColor),
                          onPressed: () async {
                            recentItem.isFav = !recentItem.isFav;
                            await recentItem.save();
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(recentItem.name,
                                  style: TextStyle(fontSize: 14, color: AppColors.textColor)),
                              Text(recentItem.code,
                                  style: TextStyle(fontSize: 11, color: AppColors.textColor)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.secondaryColor),
                          onPressed: () async {
                            await box.delete(recentItem.key);
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