import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'ad_block_service.dart';

/// 广告拦截注入器 - 使用 JavaScript 注入方式
class AdBlockInjector {
  static final AdBlockInjector _instance = AdBlockInjector._internal();
  final _adBlockService = AdBlockService();

  factory AdBlockInjector() {
    return _instance;
  }

  AdBlockInjector._internal();

  /// 生成广告拦截 JavaScript 代码
  Future<String> generateBlockScript() async {
    try {
      final filters = await _adBlockService.getCachedFilters();
      
      if (filters.isEmpty) {
        return '';
      }

      // 只使用前 100 个最常用的规则，避免脚本过大
      final topFilters = filters.take(100).toList();
      
      // 生成域名黑名单
      final domains = <String>[];
      for (final filter in topFilters) {
        if (filter.startsWith('||')) {
          final domain = filter.substring(2).split('/')[0].replaceAll('^', '');
          if (domain.isNotEmpty && !domain.contains('*')) {
            domains.add(domain);
          }
        }
      }

      if (domains.isEmpty) {
        return '';
      }

      // 生成 JavaScript 代码
      return '''
(function() {
  const blockedDomains = ${_generateDomainsArray(domains)};
  
  // 拦截 fetch
  const originalFetch = window.fetch;
  window.fetch = function(...args) {
    const url = args[0];
    if (typeof url === 'string' && shouldBlock(url)) {
      console.log('[AdBlock] Blocked fetch:', url);
      return Promise.reject(new Error('Blocked by AdBlock'));
    }
    return originalFetch.apply(this, args);
  };
  
  // 拦截 XMLHttpRequest
  const originalOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url, ...rest) {
    if (shouldBlock(url)) {
      console.log('[AdBlock] Blocked XHR:', url);
      return;
    }
    return originalOpen.apply(this, [method, url, ...rest]);
  };
  
  // 检查是否应该拦截
  function shouldBlock(url) {
    if (!url) return false;
    const urlLower = url.toLowerCase();
    
    // 快速关键词检查
    if (!urlLower.includes('ad') && 
        !urlLower.includes('banner') && 
        !urlLower.includes('tracking') &&
        !urlLower.includes('analytics')) {
      return false;
    }
    
    // 检查域名黑名单
    for (const domain of blockedDomains) {
      if (urlLower.includes(domain)) {
        return true;
      }
    }
    
    return false;
  }
  
  console.log('[AdBlock] Initialized with ' + blockedDomains.length + ' domains');
})();
''';
    } catch (e) {
      print('Error generating block script: $e');
      return '';
    }
  }

  String _generateDomainsArray(List<String> domains) {
    final items = domains.map((d) => "'$d'").join(', ');
    return '[$items]';
  }

  /// 注入广告拦截脚本到 WebView
  Future<void> injectBlockScript(InAppWebViewController controller) async {
    try {
      final script = await generateBlockScript();
      if (script.isNotEmpty) {
        await controller.evaluateJavascript(source: script);
        print('[AdBlock] Script injected successfully');
      }
    } catch (e) {
      print('Error injecting block script: $e');
    }
  }
}
