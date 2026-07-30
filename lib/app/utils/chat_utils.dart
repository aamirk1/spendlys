import 'package:intl/intl.dart';

class ChatUtils {
  static String utcToLocal(DateTime time, {bool forChat = false}) {
    DateTime localTime = time.toLocal();
    if (forChat) {
      return DateFormat('yyyy-MM-dd HH:mm').format(localTime);
    }
    return localTime.toString();
  }
}
