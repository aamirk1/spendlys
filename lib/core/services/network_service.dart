import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final isOnline = true.obs;

  @override
  void onInit() {
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      // Check if any of the results are NOT 'none'
      bool hasConnection =
          result.any((element) => element != ConnectivityResult.none);
      isOnline.value = hasConnection;
    });
    super.onInit();
  }
}
