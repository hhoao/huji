import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/appearance/appearance_cubit.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/widgets/settings/theme_color_preset_picker.dart';
import 'package:huji_app/widgets/settings/typography_scale_setting.dart';
import 'package:huji_app/widgets/settings/workspace_settings_toggle_strip.dart';
import 'package:huji_app/widgets/settings/workspace_settings_widgets.dart';
import 'package:huji_app/theme/app_typography_scale.dart';

/// Huji appearance settings — Teampilot [LayoutAppearanceInLayoutSection] subset.
class HujiAppearanceSettingsSection extends StatelessWidget {
  const HujiAppearanceSettingsSection({super.key});

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

        return SingleChildScrollView(
          child: SettingsSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsLabeledRow(
                  title: l10n.themeModeTitle,
                  subtitle: l10n.themeModeDescription,
                  trailing: WorkspaceSettingsToggleStrip<String>(
                    segments: [
                      WorkspaceToggleSegment<String>(
                        value: 'light',
                        label: l10n.themeLight,
                        icon: Icons.light_mode_outlined,
                      ),
                      WorkspaceToggleSegment<String>(
                        value: 'dark',
                        label: l10n.themeDark,
                        icon: Icons.dark_mode_outlined,
                      ),
                      WorkspaceToggleSegment<String>(
                        value: 'system',
                        label: l10n.themeSystem,
                        icon: Icons.desktop_windows_outlined,
                      ),
                    ],
                    selected: themeMode,
                    onChanged: cubit.setThemeMode,
                  ),
                ),
                SettingsLabeledRow(
                  title: l10n.themeColorPresetTitle,
                  subtitle: l10n.themeColorPresetDescription,
                  trailing: ThemeColorPresetPicker(
                    selected: normalizeThemeColorPreset(prefs.themeColorPreset),
                    onSelect: cubit.setThemeColorPreset,
                  ),
                ),
                SettingsLabeledRow(
                  title: l10n.typographyScaleTitle,
                  subtitle: l10n.typographyScaleDescription,
                  trailing: TypographyScaleSetting(
                    scaleId: normalizeTypographyScale(prefs.typographyScale),
                    customMultiplier: prefs.typographyScaleCustomMultiplier,
                    onScaleIdChanged: cubit.setTypographyScale,
                    onCustomMultiplierChanged: (v) => cubit.setTypographyScale(
                      prefs.typographyScale,
                      custom: v,
                    ),
                  ),
                ),
                SettingsLabeledRow(
                  title: l10n.uiZoomTitle,
                  subtitle: l10n.uiZoomDescription,
                  trailing: TypographyScaleSetting(
                    scaleId: normalizeTypographyScale(prefs.uiZoomScale),
                    customMultiplier: prefs.uiZoomCustomMultiplier,
                    onScaleIdChanged: cubit.setUiZoomScale,
                    onCustomMultiplierChanged: (v) => cubit.setUiZoomScale(
                      prefs.uiZoomScale,
                      custom: v,
                    ),
                  ),
                ),
                SettingsLabeledRow(
                  title: l10n.language,
                  subtitle: l10n.languageDescription,
                  trailing: WorkspaceSettingsToggleStrip<String>(
                    segments: [
                      WorkspaceToggleSegment<String>(
                        value: 'zh',
                        label: l10n.languageChinese,
                        icon: Icons.translate,
                      ),
                      WorkspaceToggleSegment<String>(
                        value: 'en',
                        label: l10n.languageEnglish,
                        icon: Icons.language,
                      ),
                    ],
                    selected: langValue,
                    onChanged: cubit.setLocale,
                  ),
                  showDividerBelow: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
