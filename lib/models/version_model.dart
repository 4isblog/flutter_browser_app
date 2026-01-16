class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String updateLog;
  final bool forceUpdate;
  final DateTime publishedAt;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.updateLog,
    required this.forceUpdate,
    required this.publishedAt,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      downloadUrl: json['downloadUrl'] as String,
      updateLog: json['updateLog'] as String,
      forceUpdate: json['forceUpdate'] as bool,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'downloadUrl': downloadUrl,
      'updateLog': updateLog,
      'forceUpdate': forceUpdate,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
}

class VersionResponse {
  final bool success;
  final bool hasUpdate;
  final String latestVersion;
  final String currentVersion;
  final UpdateInfo? updateInfo;

  VersionResponse({
    required this.success,
    required this.hasUpdate,
    required this.latestVersion,
    required this.currentVersion,
    this.updateInfo,
  });

  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    return VersionResponse(
      success: json['success'] as bool,
      hasUpdate: json['hasUpdate'] as bool,
      latestVersion: json['latestVersion'] as String,
      currentVersion: json['currentVersion'] as String,
      updateInfo: json['updateInfo'] != null
          ? UpdateInfo.fromJson(json['updateInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}
