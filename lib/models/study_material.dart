class StudyMaterial {
  final String id;
  final String userId;
  final String title;
  final String fileName;
  final String fileType; // 'pdf' or 'txt'
  final int fileSizeBytes;
  final String? storageUrl;
  final String? extractedText;
  final DateTime uploadedAt;

  StudyMaterial({
    required this.id,
    required this.userId,
    required this.title,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    this.storageUrl,
    this.extractedText,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'file_name': fileName,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'storage_url': storageUrl,
      'extracted_text': extractedText,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Note',
      fileName: json['file_name'] as String? ?? 'document',
      fileType: json['file_type'] as String? ?? 'pdf',
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      storageUrl: json['storage_url'] as String?,
      extractedText: json['extracted_text'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'].toString())
          : null,
    );
  }
}
