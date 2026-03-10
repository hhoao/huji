import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class ThemeManager extends GetxController {
  static ThemeManager get to => Get.find();

  final _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  // 加载保存的主题模式
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getBool('is_dark_mode') ?? false;
    _isDarkMode.value = savedMode;
  }

  // 切换主题模式
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    await _saveThemeMode();

    // 更新应用主题
    Get.changeTheme(
      _isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme,
    );
  }

  // 设置特定主题模式
  Future<void> setThemeMode(bool isDark) async {
    _isDarkMode.value = isDark;
    await _saveThemeMode();

    // 更新应用主题
    Get.changeTheme(
      _isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme,
    );
  }

  // 保存主题模式到本地存储
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode.value);
  }

  // 获取当前主题
  ThemeData get currentTheme =>
      _isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme;

  // 获取主题色
  Color get primaryColor => AppTheme.primaryColor;
  Color get secondaryColor => AppTheme.secondaryColor;
  Color get accentColor => AppTheme.accentColor;
}
