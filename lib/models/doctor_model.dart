// hospital_model.dart
class Hospital {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String type;
  final List<Doctor> doctors;
  final int doctorCount;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.type,
    required this.doctors,
    required this.doctorCount,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      type: json['type'] ?? '',
      doctors: (json['doctors'] as List? ?? [])
          .map((doctorJson) => Doctor.fromJson(doctorJson))
          .toList(),
      doctorCount: json['doctorCount'] ?? 0,
    );
  }
}

// doctor_model.dart
class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String? qualification;
  final bool bookingOpen;
  final List<ConsultingDay> consulting;
  final String? departmentInfo;
  final String? hospitalName;
  final String? hospitalAddress;
  final String? hospitalPhone;
  final String? hospitalId;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.qualification,
    required this.bookingOpen,
    required this.consulting,
    this.departmentInfo,
    this.hospitalName,
    this.hospitalAddress,
    this.hospitalPhone,
    this.hospitalId,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      qualification: json['qualification'],
      bookingOpen: json['bookingOpen'] ?? false,
      consulting: (json['consulting'] as List? ?? [])
          .map((consultingJson) => ConsultingDay.fromJson(consultingJson))
          .toList(),
      departmentInfo: json['department_info'],
    );
  }

  Doctor copyWith({
    String? hospitalName,
    String? hospitalAddress,
    String? hospitalPhone,
    String? hospitalId,
  }) {
    return Doctor(
      id: id,
      name: name,
      specialty: specialty,
      qualification: qualification,
      bookingOpen: bookingOpen,
      consulting: consulting,
      departmentInfo: departmentInfo,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      hospitalPhone: hospitalPhone ?? this.hospitalPhone,
      hospitalId: hospitalId ?? this.hospitalId,
    );
  }
}

class ConsultingDay {
  final String day;
  final List<Session> sessions;
  final String id;

  ConsultingDay({
    required this.day,
    required this.sessions,
    required this.id,
  });

  factory ConsultingDay.fromJson(Map<String, dynamic> json) {
    return ConsultingDay(
      day: json['day'] ?? '',
      sessions: (json['sessions'] as List? ?? [])
          .map((sessionJson) => Session.fromJson(sessionJson))
          .toList(),
      id: json['_id'] ?? '',
    );
  }
}

class Session {
  final String startTime;
  final String endTime;
  final String id;

  Session({
    required this.startTime,
    required this.endTime,
    required this.id,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}