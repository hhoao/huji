import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:huji_app/pages/system/error_page.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/router/modules/main.dart';
import 'package:huji_app/services/error_log_service.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      appRouter.go(MainRoute.mainHome);
    } catch (e, stack) {
      await ErrorLogService.instance.recordError(
        e,
        stack,
        module: 'App Initialization',
      );
      showInitErrorApp(
        error: Exception('SplashPage initialization failed: $e'),
        stackTrace: stack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 应用 Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(
                'assets/icons/logo_no_bg.png',
                width: 60,
                height: 60,
              ),
            ),

            SizedBox(height: 32),

            // 应用名称
            Text(context.hujiL10n.appTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            SizedBox(height: 8),

            Text(context.hujiL10n.splashTagline, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),

            SizedBox(height: 48),

            // 加载指示器
            const CircularProgressIndicator(),

            SizedBox(height: 16),

            Text(context.hujiL10n.splashInitializing, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
