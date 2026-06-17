/// Bundled demo videos under [assets/demo/] for onboarding and local detection trials.
class DemoVideo {
  const DemoVideo({
    required this.id,
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.sportTypeKey,
    required this.sportLabel,
    required this.matchType,
  });

  final String id;
  final String assetPath;
  final String title;
  final String subtitle;

  /// `ping_pong` or `badminton` — passed to local detection / clip pipeline.
  final String sportTypeKey;

  /// UI label: 乒乓球 / 羽毛球
  final String sportLabel;

  /// Model match type folder, e.g. `profession`, `singles`.
  final String matchType;
}

const demoVideos = <DemoVideo>[
  DemoVideo(
    id: 'ping_pong_demo',
    assetPath: 'assets/demo/ping_pong_demo.mp4',
    title: '乒乓球演示',
    subtitle: '约 23 秒 · 算法样例视频',
    sportTypeKey: 'ping_pong',
    sportLabel: '乒乓球',
    matchType: 'profession',
  ),
  DemoVideo(
    id: 'badminton_demo',
    assetPath: 'assets/demo/badminton_demo.mp4',
    title: '羽毛球演示',
    subtitle: '约 51 秒 · 算法样例视频',
    sportTypeKey: 'badminton',
    sportLabel: '羽毛球',
    matchType: 'singles',
  ),
];

DemoVideo? demoVideoById(String id) {
  for (final demo in demoVideos) {
    if (demo.id == id) return demo;
  }
  return null;
}

List<DemoVideo> demoVideosForSportLabel(String sportLabel) {
  return demoVideos.where((d) => d.sportLabel == sportLabel).toList();
}
