import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit() : super(AppThemeMode.system) {
    _load();
  }

  static const _key = 'theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_key);
    if (idx != null && idx >= 0 && idx < AppThemeMode.values.length) {
      emit(AppThemeMode.values[idx]);
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }

  ThemeMode toFlutterMode(AppThemeMode m) {
    switch (m) {
      case AppThemeMode.light: return ThemeMode.light;
      case AppThemeMode.dark:  return ThemeMode.dark;
      default:                 return ThemeMode.system;
    }
  }
}
