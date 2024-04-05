import 'package:fluttertoast/fluttertoast.dart';
import 'package:web_view/constants/colors.dart';

class ToastService {
  static final ToastService _instance = ToastService._internal();
  DateTime? lastToastTime;

  factory ToastService() {
    return _instance;
  }

  ToastService._internal();

  void showToastMessage(String message) {
    final now = DateTime.now();
    if (lastToastTime == null ||
        now.difference(lastToastTime!).inSeconds >= 1) {
      lastToastTime = now;
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: AppColors.primaryColor,
        textColor: AppColors.textColor,
        fontSize: 16.0,
      );
    }
  }
}
