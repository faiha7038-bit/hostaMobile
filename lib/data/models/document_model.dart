class Document {
  final String? id;
  final String? patientId;
  final String name;
  final String date;

  final String? fileKey;
  final String? imageUrl; 
  final String? fileName;
  final String? fileType;
  final String? fileSize;
  final String? type;
  final bool? isActive;

  Document({
    this.id,
    this.patientId,
    required this.name,
    required this.date,
    this.fileKey,
    this.imageUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.type,
    this.isActive,
  });

  factory Document.fromJson(Map<String, dynamic> json) {

    String? image = json['imageUrl']?.toString();

   
    if (image == null || image.isEmpty) {
      final raw = json['fileUrl'] ?? json['fileKey'];
      if (raw != null) {
        final value = raw.toString();
        if (value.startsWith('http')) {
          image = value;
        } else {
          const base = "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";
          image = base + (value.startsWith('/') ? value.substring(1) : value);
        }
      }
    }

    return Document(
      id: json['id']?.toString(),
      patientId: json['patientId']?.toString(),
      name: (json['name'] ?? '').toString(),
      date: json['date']?.toString() ?? '',
      imageUrl: image,
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
      fileSize: json['fileSize']?.toString(),
      type: json['type']?.toString(),
      isActive: json['isActive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'name': name,
      'date': date,
      'fileKey': fileKey,
      'imageUrl': imageUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'type': type,
      'isActive': isActive,
    };
  }

  Document copyWith({
    String? id,
    String? patientId,
    String? name,
    String? date,
    String? fileKey,
    String? imageUrl,
    String? fileName,
    String? fileType,
    String? fileSize,
    String? type,
    bool? isActive,
  }) {
    return Document(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      date: date ?? this.date,
      fileKey: fileKey ?? this.fileKey,
      imageUrl: imageUrl ?? this.imageUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
    
  }
  
}
class DocumentResponse {
  final List<Document> documents;
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int limit;

  DocumentResponse({
    required this.documents,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
  });

factory DocumentResponse.fromJson(Map<String, dynamic> json) {
  final List<dynamic> data = json['data'] ?? [];
  final Map<String, dynamic> pagination = json['pagination'] ?? {};

  return DocumentResponse(
    documents: data
        .map((e) => Document.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalItems: pagination['totalItems'] ?? 0,
    totalPages: pagination['totalPages'] ?? 1,
    currentPage: pagination['currentPage'] ?? 1,
    limit: pagination['limit'] ?? 10,
  );
}
}