class OfflineSubmission {
  final String id;
  final String url;
  final String method;
  final Map<String, dynamic> data;
  final Map<String, List<String>> files; // Field name -> List of file paths
  final DateTime timestamp;
  final String title; // For display in drafts
  final Map<String, dynamic>?
      formSchema; // To reconstruct the form or prepare data

  OfflineSubmission({
    required this.id,
    required this.url,
    required this.method,
    required this.data,
    required this.files,
    required this.timestamp,
    required this.title,
    this.formSchema,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'method': method,
      'data': data,
      'files': files,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'formSchema': formSchema,
    };
  }

  factory OfflineSubmission.fromJson(Map<String, dynamic> json) {
    return OfflineSubmission(
      id: json['id'],
      url: json['url'],
      method: json['method'],
      data: Map<String, dynamic>.from(json['data']),
      files: (json['files'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
      timestamp: DateTime.parse(json['timestamp']),
      title: json['title'],
      formSchema: json['formSchema'] != null
          ? Map<String, dynamic>.from(json['formSchema'])
          : null,
    );
  }
}
