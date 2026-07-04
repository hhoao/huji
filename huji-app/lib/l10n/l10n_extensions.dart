import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';
export 'huji_l10n_helpers.dart';

extension HujiL10n on BuildContext {
  HujiLocalizations get hujiL10n => HujiLocalizations.of(this);
}
