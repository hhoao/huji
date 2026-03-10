import 'package:uuid/uuid.dart';

class MemoryStreamService {
  static final MemoryStreamService _instance = MemoryStreamService._();
  static MemoryStreamService get instance => _instance;
  factory MemoryStreamService() => instance;
  MemoryStreamService._();

  final Map<String, Stream<dynamic>> _streamMap = {};

  Future<Stream<dynamic>?> getStream(String streamId) async {
    if (_streamMap.containsKey(streamId)) {
      return _streamMap[streamId]!;
    }
    return null;
  }

  String addStream(Stream<dynamic> stream) {
    final streamId = Uuid().v4();
    _streamMap[streamId] = stream;
    return streamId;
  }

  void removeStream(String streamId) {
    final removed = _streamMap.remove(streamId);
    if (removed != null) {
      removed.drain();
    }
  }
}
