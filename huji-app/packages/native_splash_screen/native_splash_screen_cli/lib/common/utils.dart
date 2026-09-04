import 'dart:io';

import 'package:image/image.dart' show Color, ColorRgba8;
import 'package:path/path.dart' as path;

/// Escapes special characters in strings for C++ code
String escapeString(String input) {
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll("'", "\\'")
      .replaceAll('`', '\\`')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}

/// Original function adapted for robustness and using `path` package.
///
/// Tries to find or create a "runner" directory (case-insensitive) within a given base path.
/// Defaults to looking inside `originPath/platform/runner`.
///
/// - [originPath]: The root path of the project.
/// - [platformSubDir]: The platform directory name (e.g., "macos", "linux", "windows").
/// - [customRunnerPath]: An optional full path that might already point to or include "runner".
///   If provided, this function will try to use it or find "runner" within it.
///
/// This revised function aims to be more robust for locating the conventional runner directory.
Directory locateOrCreateRunnerDir(
  String originPath,
  String platformSubDir, [
  String? customRunnerPath,
]) {
  String basePath;

  if (customRunnerPath != null && customRunnerPath.isNotEmpty) {
    basePath = customRunnerPath;
  } else {
    basePath = path.join(originPath, platformSubDir);
  }

  // Normalize using the path package
  basePath = path.normalize(basePath);

  // Check if basePath itself ends with "runner" (case-insensitive)
  if (path.basename(basePath).toLowerCase() == "runner") {
    return Directory(basePath); // basePath is already the runner directory
  }

  // If not, look for a "runner" (or "Runner" on macOS) subdirectory
  String runnerDirName = "runner";
  if (Platform.isMacOS &&
      Directory(path.join(basePath, "Runner")).existsSync()) {
    // Check for macOS "Runner" first if on macOS and it exists
    runnerDirName = "Runner";
  } else if (Directory(path.join(basePath, "runner")).existsSync()) {
    // Check for lowercase "runner" if uppercase wasn't found or not on macOS
    runnerDirName = "runner";
  } else {
    // Neither "Runner" nor "runner" exists as a subdirectory,
    runnerDirName = Platform.isMacOS ? "Runner" : "runner";
  }

  final runnerPath = path.join(basePath, runnerDirName);
  return Directory(runnerPath);
}

/// Checks if a required build file exists within the given directory.
///
/// If the file exists, returns a [Directory] object representing it.
/// Otherwise, throws a [FileSystemException].
///
/// - [directoryPath]: The path to the directory where the file should exist.
/// - [fileName]: The name of the file to check for (e.g., "native_splash_screen.cmake", "NativeSplashScreen.swift").
Directory requireBuildFile(String directoryPath, String fileName) {
  // Normalize the directory path first to handle any OS-specific quirks or trailing slashes
  final normalizedDirPath = path.normalize(directoryPath);

  // Construct the full path to the file using the path package for cross-platform compatibility
  final String filePath = path.join(normalizedDirPath, fileName);
  final file = File(filePath);

  if (file.existsSync()) {
    return Directory(normalizedDirPath);
  } else {
    throw FileSystemException();
  }
}

/// Parse color string to standardized [Color] object
/// Supports formats:
/// - Hex: #RGB, #RGBA, #RRGGBB, #RRGGBBAA
/// - RGB/RGBA/ARGB: rgb(r,g,b), rgba(r,g,b,a), argb(a,r,g,b)
/// - Comma separated: "r, g, b", "r, g, b, a"
Color parseColor(String colorString) {
  // Trim whitespace
  final color = colorString.trim();

  // Hex format: #RRGGBBAA
  if (RegExp(r'^#[0-9A-Fa-f]{8}$').hasMatch(color)) {
    final r = int.parse(color.substring(1, 3), radix: 16);
    final g = int.parse(color.substring(3, 5), radix: 16);
    final b = int.parse(color.substring(5, 7), radix: 16);
    final a = int.parse(color.substring(7, 9), radix: 16);
    return ColorRgba8(r, g, b, a);
  }

  // Hex format: #RRGGBB — assume full alpha
  if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
    final r = int.parse(color.substring(1, 3), radix: 16);
    final g = int.parse(color.substring(3, 5), radix: 16);
    final b = int.parse(color.substring(5, 7), radix: 16);
    return ColorRgba8(r, g, b, 255);
  }

  // 4-digit hex (RGBA)
  if (RegExp(r'^#[0-9A-Fa-f]{4}').hasMatch(color)) {
    final r = int.parse(color[1]).clamp(0, 255);
    final g = int.parse(color[2]).clamp(0, 255);
    final b = int.parse(color[3]).clamp(0, 255);
    final a = int.parse(color[4]).clamp(0, 255);
    return ColorRgba8(r, g, b, a);
  }

  // 3-digit hex (RGB), add full alpha
  if (RegExp(r'^#[0-9A-Fa-f]{3}').hasMatch(color)) {
    final r = int.parse(color[1]).clamp(0, 255);
    final g = int.parse(color[2]).clamp(0, 255);
    final b = int.parse(color[3]).clamp(0, 255);
    return ColorRgba8(r, g, b, 255);
  }

  // RGB/RGBA function notation: rgb(r,g,b) or rgba(r,g,b,a)
  final rgbRegex = RegExp(
    r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([0-9.]+))?\s*\)',
  );
  final rgbMatch = rgbRegex.firstMatch(color);
  if (rgbMatch != null) {
    final r = int.parse(rgbMatch.group(1)!).clamp(0, 255);
    final g = int.parse(rgbMatch.group(2)!).clamp(0, 255);
    final b = int.parse(rgbMatch.group(3)!).clamp(0, 255);

    // Parse alpha (0.0-1.0) or default to 1.0
    double alpha = 1.0;
    if (rgbMatch.group(4) != null) {
      alpha = double.parse(rgbMatch.group(4)!).clamp(0.0, 1.0);
    }

    final aInt = (alpha * 255).round().clamp(0, 255);
    return ColorRgba8(r, g, b, aInt);
  }

  // ARGB function notation: argb(a,r,g,b)
  final argbRegex = RegExp(
    r'argb\(\s*([0-9.]+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)',
  );
  final argbMatch = argbRegex.firstMatch(color);
  if (argbMatch != null) {
    // Parse alpha (could be 0.0-1.0 or 0-255)
    final aValue = argbMatch.group(1)!;
    int aInt;
    if (aValue.contains('.')) {
      final aDouble = double.parse(aValue).clamp(0.0, 1.0);
      aInt = (aDouble * 255).round().clamp(0, 255);
    } else {
      aInt = int.parse(aValue).clamp(0, 255);
    }

    final r = int.parse(argbMatch.group(2)!).clamp(0, 255);
    final g = int.parse(argbMatch.group(3)!).clamp(0, 255);
    final b = int.parse(argbMatch.group(4)!).clamp(0, 255);

    return ColorRgba8(r, g, b, aInt);
  }

  // Comma-separated values: "r, g, b", "r, g, b, a"
  final commaSeparatedValues = color.split(',').map((s) => s.trim()).toList();
  if (commaSeparatedValues.length >= 3) {
    int r, g, b;
    int aInt = 255;

    if (commaSeparatedValues.length == 3) {
      // r, g, b format
      r = int.parse(commaSeparatedValues[0]).clamp(0, 255);
      g = int.parse(commaSeparatedValues[1]).clamp(0, 255);
      b = int.parse(commaSeparatedValues[2]).clamp(0, 255);
    } else {
      // r, g, b, a format
      r = int.parse(commaSeparatedValues[0]).clamp(0, 255);
      g = int.parse(commaSeparatedValues[1]).clamp(0, 255);
      b = int.parse(commaSeparatedValues[2]).clamp(0, 255);

      final aValue = commaSeparatedValues[3];
      if (aValue.contains('.')) {
        final aDouble = double.parse(aValue).clamp(0.0, 1.0);
        aInt = (aDouble * 255).round().clamp(0, 255);
      } else {
        aInt = int.parse(aValue).clamp(0, 255);
      }
    }

    return ColorRgba8(r, g, b, aInt);
  }

  // Default to transparent black if format is unrecognized
  return ColorRgba8(0, 0, 0, 0);
}

String colorHex(Color color) {
  return ''
          '${color.a.toInt().toRadixString(16).padLeft(2, '0')}'
          '${color.r.toInt().toRadixString(16).padLeft(2, '0')}'
          '${color.g.toInt().toRadixString(16).padLeft(2, '0')}'
          '${color.b.toInt().toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

extension StringCasingExtension on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Examples:
  /// "release" -> "Release"
  String capitalizeFirstLetter() {
    if (isEmpty) {
      return "";
    }
    if (length == 1) {
      return toUpperCase();
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
