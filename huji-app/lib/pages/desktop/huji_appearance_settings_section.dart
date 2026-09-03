import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:huji_app/appearance/appearance_cubit.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/settings/settings_manager.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/widgets/desktop/app_switch.dart';
import 'package:huji_app/widgets/settings/theme_color_preset_picker.dart';
import 'package:huji_app/widgets/settings/typography_scale_setting.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:shared_ui/shared_ui.dart';

/// Huji appearance settings — Teampilot [LayoutAppearanceInLayoutSection] subset.
///
/// Shared by the desktop settings page and the mobile appearance sub-page:
/// theme mode / color preset / text scale / language come from
/// [AppearanceCubit]; push notifications comes from [SettingsManager].
/// [showUiZoom] stays desktop-only because [UiZoom] is only wired into the
/// desktop [MaterialApp] builder.
class HujiAppearanceSettingsSection extends StatelessWidget {
  const HujiAppearanceSettingsSection({
    this.showUiZoom = true,
    this.withCard = true,
    this.preferVerticalLayout = false,
    this.showPushNotifications = true,
    this.showLanguage = true,
    super.key,
  });

  /// Interface-zoom row — desktop only ([UiZoom] is desktop-wired).
  final bool showUiZoom;

  /// Wrap rows in a [TpCard.outlined] (desktop section body). The mobile
  /// appearance page renders rows inside its own grouped card.
  final bool withCard;

  /// Stack label above control (mobile). Horizontal [TpPreferenceRow] trailings
  /// collapse on narrow widths and make the section look empty.
  final bool preferVerticalLayout;

  final bool showPushNotifications;
  final bool showLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cubit = context.read<AppearanceCubit>();

    return BlocBuilder<AppearanceCubit, AppearancePreferences>(
      builder: (context, prefs) {
        var themeMode = prefs.themeMode;
        if (themeMode != 'light' && themeMode != 'dark' && themeMode != 'system') {
          themeMode = 'system';
        }
        final langValue = prefs.locale.startsWith('zh') ? 'zh' : 'en';

        Widget row({
          required String title,
          String? subtitle,
          required Widget child,
          bool showDividerBelow = true,
        }) {
          return _AppearancePreferenceTile(
            title: title,
            subtitle: subtitle,
            verticalLayout: preferVerticalLayout,
            showDividerBelow: showDividerBelow,
            child: child,
          );
        }

        final rows = <Widget>[
          row(
            title: l10n.themeModeTitle,
            subtitle: l10n.themeModeDescription,
            child: TpSegmentedPicker<String>(
              selected: themeMode,
              onChanged: cubit.setThemeMode,
              segments: [
                TpSegmentedOption(
                  value: 'light',
                  label: l10n.themeLight,
                  icon: Icons.light_mode_outlined,
                ),
                TpSegmentedOption(
                  value: 'dark',
                  label: l10n.themeDark,
                  icon: Icons.dark_mode_outlined,
                ),
                TpSegmentedOption(
                  value: 'system',
                  label: l10n.themeSystem,
                  icon: Icons.desktop_windows_outlined,
                ),
              ],
            ),
          ),
          row(
            title: l10n.themeColorPresetTitle,
            subtitle: l10n.themeColorPresetDescription,
            child: Align(
              alignment: preferVerticalLayout
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: ThemeColorPresetPicker(
                selected: normalizeThemeColorPreset(prefs.themeColorPreset),
                onSelect: cubit.setThemeColorPreset,
              ),
            ),
          ),
          row(
            title: l10n.typographyScaleTitle,
            subtitle: l10n.typographyScaleDescription,
            child: TypographyScaleSetting(
              scaleId: normalizeTypographyScale(prefs.typographyScale),
              customMultiplier: prefs.typographyScaleCustomMultiplier,
              onScaleIdChanged: cubit.setTypographyScale,
              onCustomMultiplierChanged: (v) => cubit.setTypographyScale(
                prefs.typographyScale,
                custom: v,
              ),
              expandToWidth: preferVerticalLayout,
            ),
          ),
          if (showUiZoom)
            row(
              title: l10n.uiZoomTitle,
              subtitle: l10n.uiZoomDescription,
              child: TypographyScaleSetting(
                scaleId: normalizeTypographyScale(prefs.uiZoomScale),
                customMultiplier: prefs.uiZoomCustomMultiplier,
                onScaleIdChanged: cubit.setUiZoomScale,
                onCustomMultiplierChanged: (v) => cubit.setUiZoomScale(
                  prefs.uiZoomScale,
                  custom: v,
                ),
                expandToWidth: preferVerticalLayout,
              ),
            ),
          if (showPushNotifications &&
              PlatformCapability.supportsBackgroundService)
            row(
              title: l10n.settingsPushNotifications,
              child: preferVerticalLayout
                  ? Obx(
                      () => Align(
                        alignment: Alignment.centerLeft,
                        child: Switch.adaptive(
                          value: SettingsManager.to.notifications,
                          onChanged: (value) async {
                            await SettingsManager.to.setNotifications(value);
                          },
                        ),
                      ),
                    )
                  : Obx(
                      () => AppSwitch(
                        active: SettingsManager.to.notifications,
                        onTap: () async {
                          await SettingsManager.to.setNotifications(
                            !SettingsManager.to.notifications,
                          );
                        },
                      ),
                    ),
            ),
          if (showLanguage)
            row(
              title: l10n.language,
              subtitle: l10n.languageDescription,
              showDividerBelow: false,
              child: TpSegmentedPicker<String>(
                selected: langValue,
                onChanged: cubit.setLocale,
                segments: [
                  TpSegmentedOption(
                    value: 'zh',
                    label: l10n.languageChinese,
                    icon: Icons.translate,
                  ),
                  TpSegmentedOption(
                    value: 'en',
                    label: l10n.languageEnglish,
                    icon: Icons.language,
                  ),
                ],
              ),
            ),
        ];

        if (!withCard) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          );
        }

        return SingleChildScrollView(
          child: TpCard.outlined(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          ),
        );
      },
    );
  }
}

class _AppearancePreferenceTile extends StatelessWidget {
  const _AppearancePreferenceTile({
    required this.title,
    required this.child,
    this.subtitle,
    this.verticalLayout = false,
    this.showDividerBelow = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool verticalLayout;
  final bool showDividerBelow;

  @override
  Widget build(BuildContext context) {
    if (!verticalLayout) {
      return TpPreferenceRow(
        title: title,
        subtitle: subtitle,
        trailing: child,
        showDividerBelow: showDividerBelow,
      );
    }

    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          height: 1.35,
        ) ??
        styles.md;
    final hasSub = TpPreferenceRow.hasSubtitle(subtitle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: TpPreferenceRow.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: titleStyle),
              if (hasSub) ...[
                const SizedBox(height: 4),
                Text(subtitle!.trim(), style: styles.mutedSm),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
        if (showDividerBelow)
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
