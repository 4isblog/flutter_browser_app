class NavigationItem {
  final String id;
  final String name;
  final String url;
  final String? icon;
  final DateTime createdAt;

  NavigationItem({
    required this.id,
    required this.name,
    required this.url,
    this.icon,
    required this.createdAt,
  });

  factory NavigationItem.fromJson(Map<String, dynamic> json) {
    return NavigationItem(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class NavigationResponse {
  final bool success;
  final List<NavigationItem> data;

  NavigationResponse({
    required this.success,
    required this.data,
  });

  factory NavigationResponse.fromJson(Map<String, dynamic> json) {
    return NavigationResponse(
      success: json['success'] as bool,
      data: (json['data'] as List)
          .map((item) => NavigationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
