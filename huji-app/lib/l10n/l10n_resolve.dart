import 'dart:ui';

import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/router/app_router.dart';

HujiLocalizations resolveHujiL10n([HujiLocalizations? l10n]) {
  if (l10n != null) return l10n;

  // GoRouter / WidgetsFlutterBinding are root-isolate only; background workers
  // (e.g. LocalDetectionIsolateRunner) must use lookupHujiLocalizations.
  // Do not use implicitView here — it asserts when no view exists on worker isolates.
  if (PlatformDispatcher.instance.views.isNotEmpty) {
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      return HujiLocalizations.of(context);
    }
  }

  final locale = PlatformDispatcher.instance.locale;
  return lookupHujiLocalizations(
    locale.languageCode == 'en' ? const Locale('en') : const Locale('zh'),
  );
}
