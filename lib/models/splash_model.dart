class SplashConfig {
  final String imageUrl;
  final int duration;
  final String backgroundColor;
  final DateTime updatedAt;

  SplashConfig({
    required this.imageUrl,
    required this.duration,
    required this.backgroundColor,
    required this.updatedAt,
  });

  factory SplashConfig.fromJson(Map<String, dynamic> json) {
    return SplashConfig(
      imageUrl: json['imageUrl'] as String,
      duration: json['duration'] as int,
      backgroundColor: json['backgroundColor'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'duration': duration,
      'backgroundColor': backgroundColor,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class SplashResponse {
  final bool success;
  final SplashConfig? data;

  SplashResponse({
    required this.success,
    this.data,
  });

  factory SplashResponse.fromJson(Map<String, dynamic> json) {
    return SplashResponse(
      success: json['success'] as bool,
      data: json['data'] != null
          ? SplashConfig.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
