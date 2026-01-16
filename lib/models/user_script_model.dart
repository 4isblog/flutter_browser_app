class UserScriptModel {
  final String id;
  final String name;
  final String description;
  final String code;
  final List<String> matchUrls; // URL 匹配规则
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? author;
  final String? version;
  final String? icon;

  UserScriptModel({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    required this.matchUrls,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.version,
    this.icon,
  });

  factory UserScriptModel.fromJson(Map<String, dynamic> json) {
    return UserScriptModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      code: json['code'] as String,
      matchUrls: (json['matchUrls'] as List).cast<String>(),
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      author: json['author'] as String?,
      version: json['version'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'matchUrls': matchUrls,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'author': author,
      'version': version,
      'icon': icon,
    };
  }

  UserScriptModel copyWith({
    String? id,
    String? name,
    String? description,
    String? code,
    List<String>? matchUrls,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? author,
    String? version,
    String? icon,
  }) {
    return UserScriptModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      matchUrls: matchUrls ?? this.matchUrls,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      version: version ?? this.version,
      icon: icon ?? this.icon,
    );
  }

  /// 检查 URL 是否匹配脚本规则
  bool matchesUrl(String url) {
    if (matchUrls.isEmpty) return false;
    
    for (final pattern in matchUrls) {
      if (_matchPattern(url, pattern)) {
        return true;
      }
    }
    return false;
  }

  /// URL 模式匹配
  bool _matchPattern(String url, String pattern) {
    // 支持通配符 * 和 ?
    // * 匹配任意字符
    // ? 匹配单个字符
    
    if (pattern == '*') return true;
    if (pattern == url) return true;
    
    // 转换为正则表达式
    String regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');
    
    try {
      final regex = RegExp('^$regexPattern\$');
      return regex.hasMatch(url);
    } catch (e) {
      return false;
    }
  }
}
