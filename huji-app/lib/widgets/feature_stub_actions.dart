import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/shared_ui.dart';

/// Shared "feature not ready yet" interactions used on both mobile and desktop.
abstract final class FeatureStubActions {
  static void showInDevelopment(
    BuildContext context, {
    String? featureName,
  }) {
    final l10n = context.hujiL10n;
    TpToast.show(
      context,
      message: featureName != null
          ? l10n.namedFeatureInDevelopment(featureName)
          : l10n.featureInDevelopment,
      variant: TpToastVariant.warning,
    );
  }

  static void showPresetComingSoon(BuildContext context) {
    TpToast.show(
      context,
      message: context.hujiL10n.presetComingSoon,
      variant: TpToastVariant.warning,
    );
  }

  static void showPrivacyPolicy(BuildContext context) {
    showInDevelopment(
      context,
      featureName: context.hujiL10n.settingsPrivacyPolicy,
    );
  }

  static void showUserAgreement(BuildContext context) {
    showInDevelopment(
      context,
      featureName: context.hujiL10n.settingsUserAgreement,
    );
  }

  static void showOpenFolder(BuildContext context) {
    showInDevelopment(context);
  }
}
