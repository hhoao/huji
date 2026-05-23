import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager extends GetxController {
  static SettingsManager get to => Get.find();

  // 设置项的响应式变量
  final _notifications = true.obs;
  final _language = '简体中文'.obs;

  // Getters
  bool get notifications => _notifications.value;
  String get language => _language.value;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notifications.value = prefs.getBool('notifications') ?? true;
    _language.value = prefs.getString('language') ?? '简体中文';
  }

  // 设置通知开关
  Future<void> setNotifications(bool value) async {
    _notifications.value = value;
    await _saveNotifications();
  }

  // 设置语言
  Future<void> setLanguage(String value) async {
    _language.value = value;
    await _saveLanguage();
  }

  // 保存通知设置
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notifications.value);
  }

  // 保存语言设置
  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language.value);
  }
}
