/// Resolved ONNX model ready for inference on disk.
///
/// Created on the UI isolate by [OnnxModelAssetResolver] and passed into
/// worker isolates — workers must never load Flutter assets directly.
/// Platform-agnostic: Android / iOS / desktop all run the same ONNX models.
class InferenceSpec {
  final String modelFilePath;
  final List<String> classNames;
  final String sportType;
  final String matchType;

  const InferenceSpec({
    required this.modelFilePath,
    required this.classNames,
    required this.sportType,
    required this.matchType,
  });

  Map<String, dynamic> toIsolateMessage() => {
        'modelFilePath': modelFilePath,
        'classNames': classNames,
        'sportType': sportType,
        'matchType': matchType,
      };

  factory InferenceSpec.fromIsolateMessage(Map<String, dynamic> message) {
    return InferenceSpec(
      modelFilePath: message['modelFilePath'] as String,
      classNames: List<String>.from(message['classNames'] as List),
      sportType: message['sportType'] as String,
      matchType: message['matchType'] as String,
    );
  }
}
