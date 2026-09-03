import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/desktop/huji_appearance_settings_section.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:shared_ui/shared_ui.dart';

/// Mobile appearance settings — same controls as desktop, vertical layout.
class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = context.cs;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.appearance),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            l10n.appearancePageSubtitle,
            style: TpTextStyles.of(context).md.copyWith(
              color: cs.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          TpCard.elevated(
            child: const HujiAppearanceSettingsSection(
              showUiZoom: false,
              withCard: false,
              preferVerticalLayout: true,
              showPushNotifications: false,
              showLanguage: false,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
