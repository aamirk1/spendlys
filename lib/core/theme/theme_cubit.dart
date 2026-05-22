import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_storage/get_storage.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  const ThemeState(this.themeMode);

  @override
  List<Object?> get props => [themeMode];

  bool get isDarkMode => themeMode == ThemeMode.dark;
}

class ThemeCubit extends Cubit<ThemeState> {
  final GetStorage _box;
  static const _key = 'isDarkMode';

  ThemeCubit(this._box) : super(ThemeState(ThemeMode.light)) {
    _loadTheme();
  }

  void _loadTheme() {
    final isDarkMode = _box.read(_key) ?? false;
    emit(ThemeState(isDarkMode ? ThemeMode.dark : ThemeMode.light));
  }

  void switchTheme() {
    final nextDarkMode = !state.isDarkMode;
    _box.write(_key, nextDarkMode);
    emit(ThemeState(nextDarkMode ? ThemeMode.dark : ThemeMode.light));
  }
}
