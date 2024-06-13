import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:web_view/services/toast_service.dart';
import 'package:web_view/services/translation_service.dart';

Future<bool> checkInternetConnection() async {
  final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult.contains(ConnectivityResult.none)) {
    String message = TranslationService.translate('check_internet_connection');
    ToastService().showToastMessage(message);
    return false;
  }
  return true;
}
