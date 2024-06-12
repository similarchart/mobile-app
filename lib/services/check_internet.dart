import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:web_view/services/toast_service.dart';

Future<bool> checkInternetConnection() async {
  final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult.contains(ConnectivityResult.none)) {
    ToastService().showToastMessage("인터넷 연결을 확인해주세요");
    return false;
  }
  return true;
}
