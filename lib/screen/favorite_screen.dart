import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/component/bottom_banner_ad.dart';

import '../l10n/app_localizations.dart';
import '../services/preferences.dart';

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
        title: Text(AppLocalizations.of(context).translate("recents2"), style: const TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.secondaryColor,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(AppLocalizations.of(context).translate("delete_confirmation")),
                    content: Text(AppLocalizations.of(context).translate("delete_all_except_favorites")),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        // 즐겨찾기를 제외한 종목 모두 삭제
                        child: const Text('Yes'),
                        onPressed: () async {
                          final keysToDelete = <dynamic>[];
                          for (var key in recentBox.keys) {
                            final item = recentBox.get(key) as RecentItem;
                            if (!item.isFav) {
                              keysToDelete.add(key);
                            }
                          }

                          for (var key in keysToDelete) {
                            await recentBox.delete(key);
                          }

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
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: recentBox.listenable(),
              builder: (context, Box<RecentItem> box, _) {
                final items = box.values.toList();
                final favItems = items.where((item) => item.isFav).toList()
                  ..sort((a, b) => b.dateVisited.compareTo(a.dateVisited));
                final notFavItems = items.where((item) => !item.isFav).toList()
                  ..sort((a, b) => b.dateVisited.compareTo(a.dateVisited));

                final int favItemsCount = favItems.length;
                final int totalItems = favItemsCount +
                    notFavItems.length +
                    1; // +1 for the divider

                return ListView.builder(
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    if (index == favItemsCount) {
                      // Return a custom Divider with no bottom border
                      return Divider(
                          thickness: 2,
                          color: favItemsCount > 0
                              ? AppColors.textColor
                              : AppColors.primaryColor,
                          height: 1);
                    } else if (index > favItemsCount) {
                      // Adjust index for notFavItems
                      final recentItem = notFavItems[index - favItemsCount - 1];
                      return buildItem(recentItem, box, false);
                    } else {
                      // Render favItems normally
                      final recentItem = favItems[index];
                      bool isLastFavItem = (index ==
                          favItemsCount -
                              1); // Check if it's the last favorite item
                      return buildItem(recentItem, box, isLastFavItem);
                    }
                  },
                );
              },
            ),
          ),
          const BottomBannerAd(),
        ],
      ),
    );
  }

  Widget buildItem(
    RecentItem item,
    Box<RecentItem> box,
    bool isLastItem,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        border: Border(
            bottom: BorderSide(
                color:
                    isLastItem ? Colors.transparent : AppColors.secondaryColor,
                width: 1)),
      ),
      child: InkWell(
        onTap: () async {
          String lang = await LanguagePreference.getLanguageSetting();
          Uri url = Uri.parse(item.url);
          // 쿼리 파라미터 중 'lang' 파라미터 확인
          Map<String, dynamic> newQueryParameters =
              Map.from(url.queryParameters);
          newQueryParameters['lang'] = lang; // 'lang' 파라미터 업데이트
          Uri updatedUrl = url.replace(queryParameters: newQueryParameters);

          Navigator.pop(context, updatedUrl.toString());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(item.isFav ? Icons.star : Icons.star_border,
                    color: AppColors.tertiaryColor),
                onPressed: () async {
                  item.isFav = !item.isFav;
                  await item.save();
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textColor)),
                    Text(item.code,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textColor)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.secondaryColor),
                onPressed: () async {
                  await box.delete(item.key);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
