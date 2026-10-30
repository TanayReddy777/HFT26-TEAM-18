import 'dart:collection';

class DeduplicationCache {
  final int capacity;
  final LinkedHashMap<String, int> _cache = LinkedHashMap<String, int>();

  DeduplicationCache({this.capacity = 2000});

  /// Returns true if message has already been processed within cache lifetime
  bool contains(String messageId) {
    return _cache.containsKey(messageId);
  }

  /// Records a seen message with current timestamp
  void put(String messageId) {
    if (_cache.containsKey(messageId)) {
      _cache.remove(messageId);
    } else if (_cache.length >= capacity) {
      _cache.remove(_cache.keys.first);
    }
    _cache[messageId] = DateTime.now().millisecondsSinceEpoch;
  }

  void clear() {
    _cache.clear();
  }
}
