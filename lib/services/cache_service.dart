import 'dart:collection';

/// 简单的 LRU 缓存服务
class CacheService<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  CacheService({this.maxSize = 1000});

  /// 获取缓存值
  V? get(K key) {
    if (!_cache.containsKey(key)) {
      return null;
    }
    
    // 移到最后（最近使用）
    final value = _cache.remove(key)!;
    _cache[key] = value;
    return value;
  }

  /// 设置缓存值
  void set(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // 移除最旧的项
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = value;
  }

  /// 检查是否存在
  bool contains(K key) {
    return _cache.containsKey(key);
  }

  /// 清空缓存
  void clear() {
    _cache.clear();
  }

  /// 获取缓存大小
  int get size => _cache.length;

  /// 移除指定项
  void remove(K key) {
    _cache.remove(key);
  }
}

/// 广告拦截缓存服务
class AdBlockCacheService {
  static final AdBlockCacheService _instance = AdBlockCacheService._internal();
  
  // URL 拦截结果缓存
  final CacheService<String, bool> _blockCache = CacheService(maxSize: 5000);
  
  // 域名白名单缓存
  final Set<String> _whitelistCache = {};

  factory AdBlockCacheService() {
    return _instance;
  }

  AdBlockCacheService._internal();

  /// 获取拦截结果缓存
  bool? getBlockResult(String url) {
    return _blockCache.get(url);
  }

  /// 设置拦截结果缓存
  void setBlockResult(String url, bool shouldBlock) {
    _blockCache.set(url, shouldBlock);
  }

  /// 清空拦截缓存
  void clearBlockCache() {
    _blockCache.clear();
  }

  /// 更新白名单缓存
  void updateWhitelist(Set<String> whitelist) {
    _whitelistCache.clear();
    _whitelistCache.addAll(whitelist);
  }

  /// 检查是否在白名单
  bool isWhitelisted(String domain) {
    return _whitelistCache.any((whitelist) => domain.contains(whitelist));
  }

  /// 获取缓存统计
  Map<String, int> getStats() {
    return {
      'blockCacheSize': _blockCache.size,
      'whitelistSize': _whitelistCache.length,
    };
  }
}
