import 'dart:convert';
import 'dart:typed_data';

class MeshFrame {
  final String messageId;
  final int chunkIndex;
  final int totalChunks;
  final Uint8List payload;

  const MeshFrame({
    required this.messageId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.payload,
  });

  Uint8List toBytes() {
    final idBytes = utf8.encode(messageId);
    final buffer = BytesBuilder();
    buffer.addByte(idBytes.length);
    buffer.add(idBytes);
    buffer.addByte(chunkIndex);
    buffer.addByte(totalChunks);
    buffer.add(payload);
    return buffer.toBytes();
  }

  static MeshFrame? fromBytes(Uint8List bytes) {
    if (bytes.length < 4) return null;
    final idLength = bytes[0];
    if (bytes.length < 1 + idLength + 2) return null;

    final id = utf8.decode(bytes.sublist(1, 1 + idLength));
    final chunkIndex = bytes[1 + idLength];
    final totalChunks = bytes[1 + idLength + 1];
    final payload = bytes.sublist(1 + idLength + 2);

    return MeshFrame(
      messageId: id,
      chunkIndex: chunkIndex,
      totalChunks: totalChunks,
      payload: payload,
    );
  }
}

class FrameReassembler {
  final Map<String, Map<int, Uint8List>> _buffers = {};
  final Map<String, int> _totalExpected = {};
  final Map<String, int> _creationTimestamps = {};
  static const int bufferTtlMs = 15000;

  /// Feeds a frame into reassembler. Returns complete payload string when all frames arrive, or null if incomplete.
  String? feedFrame(MeshFrame frame) {
    _cleanExpiredBuffers();

    final id = frame.messageId;
    _totalExpected[id] = frame.totalChunks;
    _creationTimestamps.putIfAbsent(id, () => DateTime.now().millisecondsSinceEpoch);

    _buffers.putIfAbsent(id, () => {})[frame.chunkIndex] = frame.payload;

    if (_buffers[id]!.length == frame.totalChunks) {
      final builder = BytesBuilder();
      for (int i = 0; i < frame.totalChunks; i++) {
        final chunk = _buffers[id]![i];
        if (chunk == null) return null;
        builder.add(chunk);
      }
      _cleanup(id);
      return utf8.decode(builder.toBytes());
    }

    return null;
  }

  static List<MeshFrame> fragmentPayload(String messageId, String payload, {int maxChunkSize = 400}) {
    final bytes = utf8.encode(payload);
    final totalChunks = (bytes.length / maxChunkSize).ceil();
    final frames = <MeshFrame>[];

    for (int i = 0; i < totalChunks; i++) {
      final start = i * maxChunkSize;
      final end = (start + maxChunkSize > bytes.length) ? bytes.length : start + maxChunkSize;
      frames.add(MeshFrame(
        messageId: messageId,
        chunkIndex: i,
        totalChunks: totalChunks,
        payload: Uint8List.fromList(bytes.sublist(start, end)),
      ));
    }

    return frames;
  }

  void _cleanup(String messageId) {
    _buffers.remove(messageId);
    _totalExpected.remove(messageId);
    _creationTimestamps.remove(messageId);
  }

  void _cleanExpiredBuffers() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expired = _creationTimestamps.entries
        .where((e) => now - e.value > bufferTtlMs)
        .map((e) => e.key)
        .toList();
    for (final id in expired) {
      _cleanup(id);
    }
  }
}
