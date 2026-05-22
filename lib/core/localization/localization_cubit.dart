import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_storage/get_storage.dart';

class LocalizationState extends Equatable {
  final Locale locale;
  const LocalizationState(this.locale);

  @override
  List<Object?> get props => [locale];
}

class LocalizationCubit extends Cubit<LocalizationState> {
  final GetStorage _box;

  LocalizationCubit(this._box) : super(const LocalizationState(Locale('en', 'US'))) {
    _loadLocale();
  }

  void _loadLocale() {
    final storedLocale = _box.read('languageCode') as String?;
    if (storedLocale != null && storedLocale.contains('_')) {
      final parts = storedLocale.split('_');
      emit(LocalizationState(Locale(parts[0], parts[1])));
    }
  }

  void changeLanguage(String languageCode, String countryCode) {
    final locale = Locale(languageCode, countryCode);
    _box.write('languageCode', '${languageCode}_$countryCode');
    emit(LocalizationState(locale));
  }
}
