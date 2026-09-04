class Platforms {
  final Platform? linux;
  final Platform? windows;
  final Platform? macos;

  Platforms({this.linux, this.windows, this.macos});

  bool get hasLinux =>
      linux != null && linux!.enabled != null ? linux!.enabled! : false;
  bool get hasWindows =>
      windows != null && windows!.enabled != null ? windows!.enabled! : false;
  bool get hasMacos =>
      macos != null && macos!.enabled != null ? macos!.enabled! : false;

  bool get hasAnyPlatform => hasLinux || hasWindows || hasMacos; //.. etc.

  bool canFallback() {
    bool f = false;
    if (!f && hasLinux) {
      f = linux!.canFall;
    }
    if (!f && hasWindows) {
      f = windows!.canFall;
    }
    if (!f && hasMacos) {
      f = macos!.canFall;
    }

    return f;
  }

  /// Helper to get a list of enabled platforms for logging
  String all() {
    final enabledPlatforms = <String>[];
    if (hasLinux) enabledPlatforms.add('Linux');
    if (hasWindows) enabledPlatforms.add('Windows');
    if (hasMacos) enabledPlatforms.add('Macos');

    return enabledPlatforms.join(", ");
  }
}

class Platform {
  final bool? enabled;
  final String path;
  final bool? fallback;

  Platform({this.enabled = false, required this.path, this.fallback = false});

  bool get canFall {
    return fallback ?? false;
  }
}
