class AdBlockRule {
  final String id;
  final String name;
  final String description;
  final String url; // 规则订阅 URL
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int ruleCount; // 规则数量
  final String? version;

  AdBlockRule({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.ruleCount = 0,
    this.version,
  });

  factory AdBlockRule.fromJson(Map<String, dynamic> json) {
    return AdBlockRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      url: json['url'] as String,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      ruleCount: json['ruleCount'] as int? ?? 0,
      version: json['version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'url': url,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'ruleCount': ruleCount,
      'version': version,
    };
  }

  AdBlockRule copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? ruleCount,
    String? version,
  }) {
    return AdBlockRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ruleCount: ruleCount ?? this.ruleCount,
      version: version ?? this.version,
    );
  }
}

/// 预设的广告拦截规则列表
class PresetAdBlockRules {
  static final List<AdBlockRule> presets = [
    AdBlockRule(
      id: 'easylist',
      name: 'EasyList',
      description: '最流行的广告拦截规则，拦截大部分英文网站广告',
      url: 'https://easylist.to/easylist/easylist.txt',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AdBlockRule(
      id: 'easyprivacy',
      name: 'EasyPrivacy',
      description: '拦截追踪器和分析脚本，保护隐私',
      url: 'https://easylist.to/easylist/easyprivacy.txt',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AdBlockRule(
      id: 'easylist-china',
      name: 'EasyList China',
      description: '专门针对中文网站的广告拦截规则',
      url: 'https://easylist-downloads.adblockplus.org/easylistchina.txt',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AdBlockRule(
      id: 'fanboy-annoyance',
      name: 'Fanboy Annoyances',
      description: '拦截烦人的弹窗、通知和社交媒体按钮',
      url: 'https://easylist.to/easylist/fanboy-annoyance.txt',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}
