import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:shared_ui/l10n/app_localizations.dart' as shared_ui;

/// Shared [MaterialApp] localization wiring for desktop and mobile.
abstract final class HujiLocalizationsSetup {
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    HujiLocalizations.delegate,
    shared_ui.SharedUiLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];
}
