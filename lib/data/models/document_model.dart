
enum DocumentType {
  prescription('Prescription'),
  labReport('Lab Report'),
  medicalHistory('Medical History'),
  insurance('Insurance'),
  other('Other');

  final String displayName;
  const DocumentType(this.displayName);

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => DocumentType.other,
    );
  }

  static List<String> get allTypes => 
      DocumentType.values.map((e) => e.displayName).toList();
}

// ✅ DocumentModel Class
class DocumentModel {
  final String id;
  final String patientId;
  final String documentType;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String mimeType;
  final String uploadDate;
  final String uploadedBy;
  final String? description;
  final bool isVerified;

  DocumentModel({
    required this.id,
    required this.patientId,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    required this.uploadDate,
    required this.uploadedBy,
    this.description,
    this.isVerified = false,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      documentType: json['documentType'] ?? 'Other',
      fileName: json['fileName'] ?? 'Untitled',
      fileUrl: json['fileUrl'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? 'application/octet-stream',
      uploadDate: json['uploadDate'] ?? DateTime.now().toIso8601String(),
      uploadedBy: json['uploadedBy'] ?? '',
      description: json['description'],
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'documentType': documentType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'uploadDate': uploadDate,
      'uploadedBy': uploadedBy,
      'description': description,
      'isVerified': isVerified,
    };
  }

  // ✅ Getters
  String get formattedDate {
    try {
      final date = DateTime.parse(uploadDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return uploadDate;
    }
  }

  String get formattedDateTime {
    try {
      final date = DateTime.parse(uploadDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return uploadDate;
    }
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }

  bool get isPdf => mimeType.contains('pdf') || fileExtension == 'pdf';

  bool get isImage => 
      mimeType.contains('image') || 
      ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileExtension);

  String get iconName {
    switch (documentType) {
      case 'Prescription':
        return 'medication';
      case 'Lab Report':
        return 'science';
      case 'Medical History':
        return 'history';
      case 'Insurance':
        return 'assignment';
      default:
        return 'description';
    }
  }
}