import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeViewModelProvider = StateNotifierProvider<ThemeViewModel, ThemeMode>((ref) => ThemeViewModel());

class ThemeViewModel extends StateNotifier<ThemeMode> {
  ThemeViewModel() : super(ThemeMode.system) {
    cargarPreferencia();
  }

  Future<void> cargarPreferencia() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('theme_mode') ?? 'system';
    state = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> cambiarTema(ThemeMode mode) async {
    state = mode;
    final preferences = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await preferences.setString('theme_mode', value);
  }
}
