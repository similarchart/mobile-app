import 'package:flutter/material.dart';
import 'package:web_view/constants/colors.dart';

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
                  size: 25,
                ),
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
