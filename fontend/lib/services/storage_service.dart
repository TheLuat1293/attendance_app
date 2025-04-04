import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}
