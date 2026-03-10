class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() {
    return 'NotifyException: $message';
  }
}
