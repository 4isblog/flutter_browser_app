import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/user_script_model.dart';

class UserScriptParser {
  /// 从 URL 下载并解析用户脚本
  static Future<UserScriptModel?> parseFromUrl(String url) async {
    try {
      print('Downloading script from: $url');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final content = response.body;
        return parseUserScript(content);
      } else {
        print('Failed to download script: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading script: $e');
      return null;
    }
  }

  /// 解析用户脚本内容
  static UserScriptModel? parseUserScript(String content) {
    try {
      final metadata = _extractMetadata(content);
      
      if (metadata['name'] == null) {
        return null;
      }

      return UserScriptModel(
        id: const Uuid().v4(),
        name: metadata['name']!,
        description: metadata['description'] ?? '无描述',
        code: content,
        matchUrls: metadata['match'] ?? ['*'],
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        author: metadata['author'],
        version: metadata['version'],
        icon: metadata['icon'],
      );
    } catch (e) {
      print('Error parsing script: $e');
      return null;
    }
  }

  /// 提取脚本元数据
  static Map<String, dynamic> _extractMetadata(String content) {
    final metadata = <String, dynamic>{};
    final lines = content.split('\n');
    bool inMetadataBlock = false;
    final matchUrls = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();

      // 检测元数据块开始
      if (trimmed.startsWith('// ==UserScript==')) {
        inMetadataBlock = true;
        continue;
      }

      // 检测元数据块结束
      if (trimmed.startsWith('// ==/UserScript==')) {
        break;
      }

      // 解析元数据
      if (inMetadataBlock && trimmed.startsWith('// @')) {
        final parts = trimmed.substring(3).split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(' ').trim();

          switch (key) {
            case 'name':
              metadata['name'] = value;
              break;
            case 'description':
              metadata['description'] = value;
              break;
            case 'author':
              metadata['author'] = value;
              break;
            case 'version':
              metadata['version'] = value;
              break;
            case 'icon':
              metadata['icon'] = value;
              break;
            case 'match':
            case 'include':
              matchUrls.add(value);
              break;
          }
        }
      }
    }

    if (matchUrls.isNotEmpty) {
      metadata['match'] = matchUrls;
    }

    return metadata;
  }

  /// 检测 URL 是否是用户脚本
  static bool isUserScriptUrl(String url) {
    // Greasyfork 脚本 URL
    if (url.contains('greasyfork.org') && url.contains('/scripts/')) {
      return true;
    }

    // OpenUserJS 脚本 URL
    if (url.contains('openuserjs.org') && url.contains('/scripts/')) {
      return true;
    }

    // 直接的 .user.js 文件
    if (url.endsWith('.user.js')) {
      return true;
    }

    return false;
  }

  /// 从 Greasyfork 页面 URL 获取脚本代码 URL
  static String? getScriptCodeUrl(String pageUrl) {
    try {
      final uri = Uri.parse(pageUrl);

      // Greasyfork
      if (uri.host.contains('greasyfork.org')) {
        // 例如: https://greasyfork.org/zh-CN/scripts/123-script-name
        // 转换为: https://greasyfork.org/scripts/123-script-name/code/script-name.user.js
        final pathParts = uri.path.split('/');
        if (pathParts.length >= 4 && pathParts[2] == 'scripts') {
          final scriptId = pathParts[3].split('-')[0];
          final scriptName = pathParts[3].substring(scriptId.length + 1);
          return 'https://${uri.host}/scripts/$scriptId-$scriptName/code/$scriptName.user.js';
        }
      }

      // OpenUserJS
      if (uri.host.contains('openuserjs.org')) {
        // 例如: https://openuserjs.org/scripts/username/Script_Name
        // 转换为: https://openuserjs.org/install/username/Script_Name.user.js
        if (uri.path.startsWith('/scripts/')) {
          return 'https://${uri.host}/install${uri.path.substring(8)}.user.js';
        }
      }

      // 如果已经是 .user.js 文件，直接返回
      if (pageUrl.endsWith('.user.js')) {
        return pageUrl;
      }

      return null;
    } catch (e) {
      print('Error getting script code URL: $e');
      return null;
    }
  }

  /// 从内容中提取脚本预览信息
  static Map<String, String> getScriptPreview(String content) {
    final metadata = _extractMetadata(content);
    final preview = <String, String>{};

    preview['name'] = metadata['name'] ?? '未知脚本';
    preview['description'] = metadata['description'] ?? '无描述';
    preview['author'] = metadata['author'] ?? '未知作者';
    preview['version'] = metadata['version'] ?? '1.0.0';
    
    final matchUrls = metadata['match'] as List<String>?;
    if (matchUrls != null && matchUrls.isNotEmpty) {
      preview['matches'] = matchUrls.join('\n');
    } else {
      preview['matches'] = '*';
    }

    // 计算代码行数
    final lines = content.split('\n').length;
    preview['lines'] = '$lines 行';

    return preview;
  }
}
