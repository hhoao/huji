import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Active app-owned layout spacing scale (1.0 = baseline).
///
/// Geometric spacing lives on [TpTheme]; this getter is a thin host alias for
/// code that historically read [AppSpacingTheme].
extension AppUiScaleContext on BuildContext {
  double get uiScale => tpSpacing.scale;
}
