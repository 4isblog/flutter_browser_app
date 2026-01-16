class LogoConfig {
  final String imageUrl;
  final DateTime updatedAt;

  LogoConfig({
    required this.imageUrl,
    required this.updatedAt,
  });

  factory LogoConfig.fromJson(Map<String, dynamic> json) {
    return LogoConfig(
      imageUrl: json['imageUrl'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class LogoResponse {
  final bool success;
  final LogoConfig? data;

  LogoResponse({
    required this.success,
    this.data,
  });

  factory LogoResponse.fromJson(Map<String, dynamic> json) {
    return LogoResponse(
      success: json['success'] as bool,
      data: json['data'] != null
          ? LogoConfig.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
