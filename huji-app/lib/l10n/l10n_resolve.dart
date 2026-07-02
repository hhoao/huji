import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/router/app_router.dart';

HujiLocalizations resolveHujiL10n([HujiLocalizations? l10n]) {
  if (l10n != null) return l10n;

  final context = appRouter.routerDelegate.navigatorKey.currentContext;
  if (context != null && context.mounted) {
    return HujiLocalizations.of(context);
  }

  final locale = PlatformDispatcher.instance.locale;
  return lookupHujiLocalizations(
    locale.languageCode == 'en' ? const Locale('en') : const Locale('zh'),
  );
}
