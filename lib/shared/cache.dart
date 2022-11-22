import 'package:meta/meta.dart';

/// Base class for a data cache with keys of type [K] and values of type [V].
abstract class Cache<K, V> {
  /// Get a value from cache
  @visibleForOverriding
  V? getValue(K key);

  /// Write a value to cache
  @visibleForOverriding
  void cache(K key, V value);

  /// Return true if [key] is in the cache.
  @visibleForOverriding
  bool inCache(K key);

  /// Return all values that are cached
  @visibleForOverriding
  List<V> getValues();

  /// Remove an item from the cache
  @visibleForOverriding
  void remove(K key);
}

class _LRUCacheEntry<V> {

  const _LRUCacheEntry(this.value, this.t);
  final int t;
  final V value;
}

class LRUCache<K, V> extends Cache<K, V> {

  LRUCache(this._maxSize) : _cache = {}, _t = 0;
  final Map<K, _LRUCacheEntry<V>> _cache;
  final int _maxSize;
  int _t;

  @override
  bool inCache(K key) => _cache.containsKey(key);
  
  @override
  V? getValue(K key) {
    return _cache[key]?.value;
  }

  @override
  List<V> getValues() => _cache.values.map((i) => i.value).toList();
  
  @override
  void cache(K key, V value) {
    if (_cache.length + 1 <= _maxSize) {
      // Fall through
    } else {
      if (inCache(key)) {
        _cache[key] = _LRUCacheEntry<V>(value, _t);
        _t++;
        return;
      }

      var lowestKey = _cache.keys.first;
      var t = _cache[lowestKey]!.t;
      _cache
        ..forEach((key, value) {
          if (value.t < t) {
            lowestKey = key;
            t = value.t;
          }
        })
        ..remove(lowestKey);
    }

    _cache[key] = _LRUCacheEntry<V>(value, _t);
    _t++;
  }

  @override
  void remove(K key) {
    _cache.remove(key);
  }
}
