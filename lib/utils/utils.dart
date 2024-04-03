import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:web_view/constants/colors.dart';

void showToastMessage(String message) {
  Fluttertoast.showToast(
    msg: message, // 메시지는 함수 호출 시 파라미터로 전달받음
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 1,
    backgroundColor: AppColors.primaryColor,
    textColor: AppColors.textColor,
    fontSize: 16.0,
  );
}
