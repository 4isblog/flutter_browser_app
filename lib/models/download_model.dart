class DownloadModel {
  final int? id;
  final String url;
  final String fileName;
  final String filePath;
  final int totalBytes;
  final int downloadedBytes;
  final String status; // 'downloading', 'completed', 'failed', 'paused'
  final DateTime startTime;
  final DateTime? endTime;

  DownloadModel({
    this.id,
    required this.url,
    required this.fileName,
    required this.filePath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = 'downloading',
    required this.startTime,
    this.endTime,
  });

  double get progress {
    if (totalBytes == 0) return 0.0;
    return downloadedBytes / totalBytes;
  }

  bool get isCompleted => status == 'completed';
  bool get isDownloading => status == 'downloading';
  bool get isFailed => status == 'failed';
  bool get isPaused => status == 'paused';

  DownloadModel copyWith({
    int? id,
    String? url,
    String? fileName,
    String? filePath,
    int? totalBytes,
    int? downloadedBytes,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return DownloadModel(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'fileName': fileName,
      'filePath': filePath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
    };
  }

  factory DownloadModel.fromMap(Map<String, dynamic> map) {
    return DownloadModel(
      id: map['id'] as int?,
      url: map['url'] as String,
      fileName: map['fileName'] as String,
      filePath: map['filePath'] as String,
      totalBytes: map['totalBytes'] as int? ?? 0,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
      status: map['status'] as String? ?? 'downloading',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int)
          : null,
    );
  }
}
