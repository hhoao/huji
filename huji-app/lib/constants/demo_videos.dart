/// Bundled demo videos under [assets/demo/] for onboarding and local detection trials.
class DemoVideo {
  const DemoVideo({
    required this.id,
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.sportTypeKey,
    required this.matchType,
  });

  final String id;
  final String assetPath;

  /// Fallback title when no l10n mapping exists.
  final String title;

  /// Fallback subtitle when no l10n mapping exists.
  final String subtitle;

  /// `ping_pong` or `badminton` — passed to local detection / clip pipeline.
  final String sportTypeKey;

  /// Model match type folder, e.g. `profession`, `singles`.
  final String matchType;
}

const demoVideos = <DemoVideo>[
  DemoVideo(
    id: 'ping_pong_demo',
    assetPath: 'assets/demo/ping_pong_demo.mp4',
    title: 'Ping pong demo',
    subtitle: '~23s · sample video',
    sportTypeKey: 'ping_pong',
    matchType: 'profession',
  ),
  DemoVideo(
    id: 'badminton_demo',
    assetPath: 'assets/demo/badminton_demo.mp4',
    title: 'Badminton demo',
    subtitle: '~51s · sample video',
    sportTypeKey: 'badminton',
    matchType: 'singles',
  ),
];

DemoVideo? demoVideoById(String id) {
  for (final demo in demoVideos) {
    if (demo.id == id) return demo;
  }
  return null;
}

List<DemoVideo> demoVideosForSportKey(String sportTypeKey) {
  return demoVideos.where((d) => d.sportTypeKey == sportTypeKey).toList();
}
