class PrescriptionResponse {
  final bool success;
  final List<Prescription> data;
  final Pagination pagination;
  final dynamic error;

  PrescriptionResponse({
    required this.success,
    required this.data,
    required this.pagination,
    this.error,
  });

  factory PrescriptionResponse.fromJson(Map<String, dynamic> json) {
    return PrescriptionResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List?)
              ?.map((e) => Prescription.fromJson(e))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      error: json['error'],
    );
  }
}

class Prescription {
  final int id;
  final int? bookingId;
  final String? prescribedBy;
  final int userId;
  final int patientId;
  final int doctorId;
  final int hospitalId;
  final String complaint;
  final List<Medication> medications;
  final List<dynamic> investigations;
  final String advice;
  final String? nextConsultation;
  final bool emptyStomach;
  final String? date;
  final String? deleteDate;
  final bool isActive;
  final bool isDelete;
  final String? canvasBg;
  final String? hospitalName;
  final String? patientName;
  final String? patientAge;      
  final String? patientGender;  
  final String? patientPhone;    
  final List<DesignElement> design;
  final String createdAt;
  final String updatedAt;

  Prescription({
    required this.id,
    this.bookingId,
    this.prescribedBy,
    required this.userId,
    required this.patientId,
    required this.doctorId,
    required this.hospitalId,
    required this.complaint,
    required this.medications,
    required this.investigations,
    required this.advice,
    this.nextConsultation,
    required this.emptyStomach,
    this.date,
    this.deleteDate,
    required this.isActive,
    required this.isDelete,
    this.canvasBg,
    this.hospitalName,
    this.patientName,
    required this.design,
    required this.createdAt,
    required this.updatedAt,
    this.patientAge,
    this.patientGender,
    this.patientPhone,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] ?? 0,
      bookingId: json['bookingId'],
      prescribedBy: json['prescribedBy'],
      userId: json['userId'] ?? 0,
      patientId: json['patientId'] ?? 0,
      doctorId: json['doctorId'] ?? 0,
      hospitalId: json['hospitalId'] ?? 0,
      complaint: json['complaint'] ?? '',
      medications: (json['medications'] as List?)
              ?.map((e) => Medication.fromJson(e))
              .toList() ??
          [],
      investigations: json['investigations'] ?? [],
      advice: json['advice'] ?? '',
      nextConsultation: json['next_consultation'],
      emptyStomach: json['empty_stomach'] ?? false,
      date: json['date'],
      deleteDate: json['deleteDate'],
      isActive: json['isActive'] ?? true,
      isDelete: json['isDelete'] ?? false,
      canvasBg: json['canvasBg'],
      hospitalName: json['hospitalName'],
      patientName: json['patientName'],
      design: (json['design'] as List?)
              ?.map((e) => DesignElement.fromJson(e))
              .toList() ??
          [],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      
      patientAge: json['age']?.toString(),        
      patientGender: json['gender']?.toString(), 
      patientPhone: json['contact']?.toString(),  
    );
  }
}

class Medication {
  final String medicineName;
  final String dosage;
  final String duration;
  final String frequency;
  final String timing;
  final String instructions;

  Medication({
    required this.medicineName,
    required this.dosage,
    required this.duration,
    required this.frequency,
    required this.timing,
    required this.instructions,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      medicineName: json['medicineName']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      timing: json['timing']?.toString() ?? '',
      instructions: json['instructions']?.toString() ?? '',
    );
  }
}

class DesignElement {
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final DesignStyle style;
  final String text;
  final String? content;

  DesignElement({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.style,
    required this.text,
    this.content,
  });

  factory DesignElement.fromJson(Map<String, dynamic> json) {
    return DesignElement(
      type: json['type'] ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      style: DesignStyle.fromJson(json['style'] ?? {}),
      text: json['text']?.toString() ?? '',
      content: json['content']?.toString(),
    );
  }
}

class DesignStyle {
  final String textAlign;
  final String bgColor;
  final String color;
  final String fontSize;
  final String fontWeight;

  DesignStyle({
    required this.textAlign,
    required this.bgColor,
    required this.color,
    required this.fontSize,
    required this.fontWeight,
  });

  factory DesignStyle.fromJson(Map<String, dynamic> json) {
    return DesignStyle(
      textAlign: json['textAlign'] ?? 'left',
      bgColor: json['bgColor'] ?? 'transparent',
      color: json['color'] ?? '#1e293b',
      fontSize: json['fontSize'] ?? '16px',
      fontWeight: json['fontWeight'] ?? 'normal',
    );
  }
}

class Pagination {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int limit;

  Pagination({
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      limit: json['limit'] ?? 10,
    );
  }
}