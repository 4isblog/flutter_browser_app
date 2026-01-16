import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../database/user_scripts_database.dart';
import '../models/user_script_model.dart';

class ScriptInjectionService {
  static final ScriptInjectionService _instance = ScriptInjectionService._internal();
  final _database = UserScriptsDatabase();

  factory ScriptInjectionService() {
    return _instance;
  }

  ScriptInjectionService._internal();

  /// 获取指定 URL 的所有匹配脚本
  Future<List<UserScript>> getUserScriptsForUrl(String url) async {
    try {
      final scripts = await _database.getScriptsForUrl(url);
      
      return scripts.map((script) {
        return UserScript(
          groupName: script.id,
          source: script.code,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
        );
      }).toList();
    } catch (e) {
      print('Error getting user scripts: $e');
      return [];
    }
  }

  /// 在 WebView 中注入脚本
  Future<void> injectScripts(
    InAppWebViewController controller,
    String url,
  ) async {
    try {
      final scriptModels = await _database.getScriptsForUrl(url);
      
      for (final script in scriptModels) {
        try {
          await controller.evaluateJavascript(source: script.code);
          print('Injected script: ${script.name}');
        } catch (e) {
          print('Error injecting script ${script.name}: $e');
        }
      }
    } catch (e) {
      print('Error in injectScripts: $e');
    }
  }

  /// 获取所有启用的脚本作为 UserScript 列表
  Future<List<UserScript>> getAllEnabledUserScripts() async {
    try {
      final scripts = await _database.getEnabledScripts();
      
      return scripts.map((script) {
        return UserScript(
          groupName: script.id,
          source: _wrapScript(script),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
        );
      }).toList();
    } catch (e) {
      print('Error getting enabled scripts: $e');
      return [];
    }
  }

  /// 包装脚本，添加 URL 匹配检查
  String _wrapScript(UserScriptModel script) {
    final matchUrls = script.matchUrls.map((url) => "'$url'").join(', ');
    
    return '''
(function() {
  const currentUrl = window.location.href;
  const matchUrls = [$matchUrls];
  
  function matchPattern(url, pattern) {
    if (pattern === '*') return true;
    if (pattern === url) return true;
    
    const regexPattern = pattern
      .replace(/\\./g, '\\\\.')
      .replace(/\\*/g, '.*')
      .replace(/\\?/g, '.');
    
    try {
      const regex = new RegExp('^' + regexPattern + '\$');
      return regex.test(url);
    } catch (e) {
      return false;
    }
  }
  
  let matched = false;
  for (const pattern of matchUrls) {
    if (matchPattern(currentUrl, pattern)) {
      matched = true;
      break;
    }
  }
  
  if (matched) {
    try {
      ${script.code}
    } catch (e) {
      console.error('[UserScript: ${script.name}] Error:', e);
    }
  }
})();
''';
  }
}
