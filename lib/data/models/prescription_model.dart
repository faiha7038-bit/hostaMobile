
class PrescriptionResponse {
  final bool success;
  final List<Prescription> data;
  final Pagination? pagination;
  final String? error;

  PrescriptionResponse({
    required this.success,
    required this.data,
    this.pagination,
    this.error,
  });

  factory PrescriptionResponse.fromJson(Map<String, dynamic> json) {
    List<Prescription> prescriptions = [];
    if (json['data'] != null && json['data'] is List) {
      prescriptions = List<Prescription>.from(
        json['data'].map((x) => Prescription.fromJson(x))
      );
    }
    
    return PrescriptionResponse(
      success: json['success'] ?? false,
      data: prescriptions,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      error: json['error'],
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

class Prescription {
  final int id;
  final int bookingId;
  final int patientId;
  final String? patientName;
  final String? patientPhone;
  final int? patientAge;
  final String? patientGender;
  final String complaint;
  final String? prescribedBy;
  final String? hospitalName;
  final List<Medication> medications;
  final String? investigations;
  final String advice;
  final String? nextConsultation;
  final bool emptyStomach;
  final String createdAt;
  final String? canvasBg;
  
  // Vital signs
  final int? temperature;
  final int? pulse;
  final int? respiratoryRate;
  final int? spo2;
  final int? height;
  final int? weight;
  final int? bmi;
  final int? waist;
  final int? bsa;

  // Additional fields
  final int? userId;
  final int? doctorId;
  final int? hospitalId;
  final bool? isActive;
  final bool? isDelete;

  Prescription({
    required this.id,
    required this.bookingId,
    required this.patientId,
    this.patientName,
    this.patientPhone,
    this.patientAge,
    this.patientGender,
    required this.complaint,
    this.prescribedBy,
    this.hospitalName,
    required this.medications,
    this.investigations,
    required this.advice,
    this.nextConsultation,
    required this.emptyStomach,
    required this.createdAt,
    this.canvasBg,
    this.temperature,
    this.pulse,
    this.respiratoryRate,
    this.spo2,
    this.height,
    this.weight,
    this.bmi,
    this.waist,
    this.bsa,
    this.userId,
    this.doctorId,
    this.hospitalId,
    this.isActive,
    this.isDelete,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    // Handle medications
    List<Medication> medications = [];
    if (json['medications'] != null && json['medications'] is List) {
      medications = List<Medication>.from(
        json['medications'].map((x) => Medication.fromJson(x))
      );
    }

    // Handle investigations - could be String, List, or null
    String? investigations;
    if (json['investigations'] != null) {
      if (json['investigations'] is String) {
        investigations = json['investigations'];
      } else if (json['investigations'] is List) {
        final list = json['investigations'] as List;
        if (list.isNotEmpty) {
          investigations = list.join(', ');
        } else {
          investigations = '';
        }
      }
    }

    // Handle next_consultation
    String? nextConsultation = json['next_consultation'] ?? json['nextConsultation'];
    
    // Handle createdAt
    String createdAt = json['createdAt'] ?? json['date'] ?? DateTime.now().toIso8601String();

    // Handle patient age
    int? patientAge;
    if (json['age'] != null) {
      if (json['age'] is int) {
        patientAge = json['age'];
      } else if (json['age'] is String) {
        patientAge = int.tryParse(json['age']);
      }
    }

    return Prescription(
      id: json['id'] ?? 0,
      bookingId: json['bookingId'] ?? 0,
      patientId: json['patientId'] ?? 0,
      patientName: json['patientName'],
      patientPhone: json['contact'] ?? json['patientPhone'],
      patientAge: patientAge ?? json['patientAge'],
      patientGender: json['gender'] ?? json['patientGender'],
      complaint: json['complaint'] ?? '',
      prescribedBy: json['prescribedBy'],
      hospitalName: json['hospitalName'],
      medications: medications,
      investigations: investigations,
      advice: json['advice'] ?? '',
      nextConsultation: nextConsultation,
      emptyStomach: json['empty_stomach'] ?? json['emptyStomach'] ?? false,
      createdAt: createdAt,
      canvasBg: json['canvasBg'],
      temperature: json['temperature'],
      pulse: json['pulse'],
      respiratoryRate: json['respiratoryRate'],
      spo2: json['spo2'],
      height: json['height'],
      weight: json['weight'],
      bmi: json['bmi'],
      waist: json['waist'],
      bsa: json['bsa'],
      userId: json['userId'],
      doctorId: json['doctorId'],
      hospitalId: json['hospitalId'],
      isActive: json['isActive'],
      isDelete: json['isDelete'],
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
      medicineName: json['medicineName'] ?? json['medicine_name'] ?? '',
      dosage: json['dosage']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      frequency: json['frequency'] ?? '',
      timing: json['timing'] ?? '',
      instructions: json['instructions'] ?? '',
    );
  }
}