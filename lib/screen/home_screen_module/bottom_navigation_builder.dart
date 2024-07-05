import 'package:flutter/material.dart';
import 'package:web_view/constants/colors.dart';
import 'package:auto_size_text/auto_size_text.dart';

class BottomNavigationBuilder {
  static Widget buildBottomIcon(
      IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: AppColors.primaryColor,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                AutoSizeText(
                  label,
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                  maxLines: 1,
                  minFontSize: 7, // 최소 글자 크기 설정
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
