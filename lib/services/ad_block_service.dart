import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../database/ad_block_database.dart';
import '../models/ad_block_rule.dart';
import 'cache_service.dart';

class AdBlockService {
  static final AdBlockService _instance = AdBlockService._internal();
  final _database = AdBlockDatabase();
  final _cache = AdBlockCacheService();
  List<ContentBlocker>? _contentBlockers;
  
  // 统计数据
  int _blockedCount = 0;
  final Set<String> _whitelistedDomains = {};
  
  // 规则缓存 - 避免每次都查询数据库
  List<String>? _cachedFilters;
  DateTime? _filtersLoadTime;
  static const _filtersCacheDuration = Duration(minutes: 5);

  factory AdBlockService() {
    return _instance;
  }

  AdBlockService._internal();

  /// 获取拦截统计
  int get blockedCount => _blockedCount;

  /// 获取缓存统计
  Map<String, int> get cacheStats => _cache.getStats();

  /// 重置统计
  void resetStats() {
    _blockedCount = 0;
  }

  /// 添加到白名单
  void addToWhitelist(String domain) {
    _whitelistedDomains.add(domain);
    _cache.updateWhitelist(_whitelistedDomains);
    _cache.clearBlockCache(); // 清空缓存以应用新白名单
  }

  /// 从白名单移除
  void removeFromWhitelist(String domain) {
    _whitelistedDomains.remove(domain);
    _cache.updateWhitelist(_whitelistedDomains);
    _cache.clearBlockCache(); // 清空缓存以应用新白名单
  }

  /// 检查是否在白名单
  bool isWhitelisted(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      return _cache.isWhitelisted(domain);
    } catch (e) {
      return false;
    }
  }

  /// 获取白名单列表
  Set<String> get whitelistedDomains => Set.from(_whitelistedDomains);

  /// 下载并更新规则（带进度回调）
  Future<bool> updateRule(
    AdBlockRule rule, {
    Function(double progress, String status)? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, '开始下载规则...');
      
      final response = await http.get(Uri.parse(rule.url)).timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        onProgress?.call(0.3, '下载完成，解析规则...');
        
        final content = response.body;
        final filters = _parseAdBlockRules(content);
        
        onProgress?.call(0.6, '保存规则到数据库...');
        
        await _database.saveFilters(rule.id, filters);
        
        onProgress?.call(0.8, '重新加载拦截器...');
        
        // 重新加载内容拦截器
        await _loadContentBlockers();
        
        onProgress?.call(1.0, '更新完成！');
        
        return true;
      } else {
        onProgress?.call(0.0, '下载失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      onProgress?.call(0.0, '错误: $e');
      return false;
    }
  }

  /// 解析广告拦截规则
  List<String> _parseAdBlockRules(String content) {
    final filters = <String>[];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      
      // 跳过注释和空行
      if (trimmed.isEmpty || 
          trimmed.startsWith('!') || 
          trimmed.startsWith('[')) {
        continue;
      }

      // 只保留基本的 URL 拦截规则
      if (trimmed.startsWith('||') || 
          trimmed.startsWith('|') ||
          trimmed.contains('##') ||
          trimmed.contains('#@#')) {
        filters.add(trimmed);
      }
    }

    return filters;
  }

  /// 加载内容拦截器
  Future<void> _loadContentBlockers() async {
    try {
      final filters = await _database.getAllEnabledFilters();
      _contentBlockers = _convertToContentBlockers(filters);
      print('Loaded ${_contentBlockers?.length ?? 0} content blockers');
    } catch (e) {
      print('Error loading content blockers: $e');
      _contentBlockers = [];
    }
  }

  /// 将广告拦截规则转换为 ContentBlocker
  List<ContentBlocker> _convertToContentBlockers(List<String> filters) {
    final blockers = <ContentBlocker>[];

    for (final filter in filters.take(50000)) { // 限制数量避免性能问题
      try {
        final blocker = _parseFilterToContentBlocker(filter);
        if (blocker != null) {
          blockers.add(blocker);
        }
      } catch (e) {
        // 跳过无法解析的规则
        continue;
      }
    }

    return blockers;
  }

  /// 解析单个过滤规则为 ContentBlocker
  ContentBlocker? _parseFilterToContentBlocker(String filter) {
    try {
      // 处理 || 开头的规则（域名拦截）
      if (filter.startsWith('||')) {
        final domain = filter.substring(2).split('/')[0].replaceAll('^', '');
        return ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: '.*$domain.*',
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        );
      }

      // 处理 | 开头的规则（完整 URL 拦截）
      if (filter.startsWith('|') && !filter.startsWith('||')) {
        final url = filter.substring(1).replaceAll('^', '.*');
        return ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: url,
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        );
      }

      // 处理包含通配符的规则
      if (filter.contains('*')) {
        final pattern = filter
            .replaceAll('.', '\\.')
            .replaceAll('*', '.*')
            .replaceAll('^', '');
        return ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: pattern,
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        );
      }

      // 简单的关键词拦截
      return ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: '.*$filter.*',
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.BLOCK,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取内容拦截器列表
  Future<List<ContentBlocker>> getContentBlockers() async {
    if (_contentBlockers == null) {
      await _loadContentBlockers();
    }
    return _contentBlockers ?? [];
  }

  /// 获取缓存的规则列表（公开方法）
  Future<List<String>> getCachedFilters() async {
    return _getCachedFilters();
  }

  /// 获取缓存的规则列表（内部方法）
  Future<List<String>> _getCachedFilters() async {
    // 检查缓存是否有效
    if (_cachedFilters != null && 
        _filtersLoadTime != null &&
        DateTime.now().difference(_filtersLoadTime!) < _filtersCacheDuration) {
      return _cachedFilters!;
    }
    
    // 从数据库加载规则
    final filters = await _database.getAllEnabledFilters();
    _cachedFilters = filters;
    _filtersLoadTime = DateTime.now();
    
    return filters;
  }

  /// 检查 URL 是否应该被拦截（带缓存）
  Future<bool> shouldBlockUrl(String url) async {
    try {
      // 检查白名单
      if (isWhitelisted(url)) {
        return false;
      }

      // 检查缓存
      final cachedResult = _cache.getBlockResult(url);
      if (cachedResult != null) {
        if (cachedResult) {
          _blockedCount++; // 增加拦截计数
        }
        return cachedResult;
      }

      // 获取缓存的规则列表（避免每次查询数据库）
      final filters = await _getCachedFilters();
      
      // 如果没有规则，直接返回
      if (filters.isEmpty) {
        _cache.setBlockResult(url, false);
        return false;
      }
      
      bool shouldBlock = false;
      for (final filter in filters) {
        if (_matchesFilter(url, filter)) {
          shouldBlock = true;
          break;
        }
      }

      // 缓存结果
      _cache.setBlockResult(url, shouldBlock);

      if (shouldBlock) {
        _blockedCount++; // 增加拦截计数
      }
      
      return shouldBlock;
    } catch (e) {
      return false;
    }
  }

  /// 匹配过滤规则
  bool _matchesFilter(String url, String filter) {
    try {
      // 跳过元素隐藏规则 (##, #@#)
      if (filter.contains('##') || filter.contains('#@#')) {
        return false;
      }

      // 处理 || 开头的规则（域名拦截）
      if (filter.startsWith('||')) {
        final domain = filter.substring(2).split('/')[0].replaceAll('^', '');
        return url.contains(domain);
      }

      // 处理 | 开头的规则（完整 URL 拦截）
      if (filter.startsWith('|') && !filter.startsWith('||')) {
        final pattern = filter.substring(1).replaceAll('^', '');
        return url.startsWith(pattern);
      }

      // 处理包含通配符的规则
      if (filter.contains('*')) {
        final regexPattern = filter
            .replaceAll('.', r'\.')
            .replaceAll('*', '.*')
            .replaceAll('^', r'[/\?&]');
        
        try {
          final regex = RegExp(regexPattern);
          return regex.hasMatch(url);
        } catch (e) {
          return false;
        }
      }

      // 简单的关键词匹配
      return url.contains(filter);
    } catch (e) {
      return false;
    }
  }

  /// 重新加载所有规则
  Future<void> reloadRules() async {
    await _loadContentBlockers();
    _cache.clearBlockCache(); // 清空缓存以应用新规则
    _cachedFilters = null; // 清空规则缓存
    _filtersLoadTime = null;
  }

  /// 清除缓存
  void clearCache() {
    _contentBlockers = null;
    _cache.clearBlockCache();
    _cachedFilters = null;
    _filtersLoadTime = null;
  }
}
