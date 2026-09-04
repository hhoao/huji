import '../models/flavor.dart';
import '../models/platforms.dart';

class SplashScreenConfig {
  final Platforms platforms;
  final Flavor release;
  final Flavor debug;
  final Flavor profile;
  Flavor fallback;
  // final List<Flavor>? custom;
  SplashScreenConfig({
    required this.platforms,
    required this.release,
    required this.debug,
    required this.profile,
    required this.fallback,
    // this.custom,
  });
}
