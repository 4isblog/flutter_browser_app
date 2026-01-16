class BrowserHistory {
  final int? id;
  final String url;
  final String title;
  final String? favicon;
  final DateTime visitTime;

  BrowserHistory({
    this.id,
    required this.url,
    required this.title,
    this.favicon,
    required this.visitTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'favicon': favicon,
      'visitTime': visitTime.millisecondsSinceEpoch,
    };
  }

  factory BrowserHistory.fromMap(Map<String, dynamic> map) {
    return BrowserHistory(
      id: map['id'],
      url: map['url'],
      title: map['title'],
      favicon: map['favicon'],
      visitTime: DateTime.fromMillisecondsSinceEpoch(map['visitTime']),
    );
  }
}
