import 'package:fluttertoast/fluttertoast.dart';
import 'package:web_view/constants/colors.dart';
import 'dart:async';

class ToastService {
  static final ToastService _instance = ToastService._internal();

  factory ToastService() {
    return _instance;
  }

  ToastService._internal();

  void showToastMessage(String message, {double durationInSeconds = 1, ToastGravity gravity = ToastGravity.BOTTOM}) {
    // 기존에 표시되고 있는 메시지를 제거
    Fluttertoast.cancel();

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: AppColors.primaryColor,
      textColor: AppColors.textColor,
      fontSize: 16.0,
    );

    if (durationInSeconds < 1) {
      Timer(Duration(milliseconds: (durationInSeconds * 1000).toInt()), () {
        Fluttertoast.cancel();
      });
    }
  }
}