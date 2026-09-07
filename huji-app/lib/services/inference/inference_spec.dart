/// Resolved ncnn model ready for inference on disk.
///
/// Created on the UI isolate by [NcnnModelAssetResolver] and passed into
/// worker isolates — workers must never load Flutter assets directly.
/// Platform-agnostic: Android / iOS / desktop all run the same ncnn models.
class InferenceSpec {
  final String paramFilePath;
  final String binFilePath;
  final List<String> classNames;
  final String sportType;
  final String matchType;

  const InferenceSpec({
    required this.paramFilePath,
    required this.binFilePath,
    required this.classNames,
    required this.sportType,
    required this.matchType,
  });

  Map<String, dynamic> toIsolateMessage() => {
        'paramFilePath': paramFilePath,
        'binFilePath': binFilePath,
        'classNames': classNames,
        'sportType': sportType,
        'matchType': matchType,
      };

  factory InferenceSpec.fromIsolateMessage(Map<String, dynamic> message) {
    return InferenceSpec(
      paramFilePath: message['paramFilePath'] as String,
      binFilePath: message['binFilePath'] as String,
      classNames: List<String>.from(message['classNames'] as List),
      sportType: message['sportType'] as String,
      matchType: message['matchType'] as String,
    );
  }
}
