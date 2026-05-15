// // hospital_model.dart
// class Hospital {
//   final String id;
//   final String name;
//   final String address;
//   final String phone;
//   final String email;
//   final String type;
//   final List<Doctor> doctors;
//   final int doctorCount;

//   Hospital({
//     required this.id,
//     required this.name,
//     required this.address,
//     required this.phone,
//     required this.email,
//     required this.type,
//     required this.doctors,
//     required this.doctorCount,
//   });

//   factory Hospital.fromJson(Map<String, dynamic> json) {
//     return Hospital(
//       id: json['id'] ?? '',
//       name: json['name'] ?? '',
//       address: json['address'] ?? '',
//       phone: json['phone'] ?? '',
//       email: json['email'] ?? '',
//       type: json['type'] ?? '',
//       doctors: (json['doctors'] as List? ?? [])
//           .map((doctorJson) => Doctor.fromJson(doctorJson))
//           .toList(),
//       doctorCount: json['doctorCount'] ?? 0,
//     );
//   }
// }

// // doctor_model.dart
// class Doctor {
//   final String id;
//   final String name;
//   final String specialty;
//   final String? qualification;
//   final bool bookingOpen;
//   final List<ConsultingDay> consulting;
//   final String? departmentInfo;
//   final String? hospitalName;
//   final String? hospitalAddress;
//   final String? hospitalPhone;
//   final String? hospitalId;

//   Doctor({
//     required this.id,
//     required this.name,
//     required this.specialty,
//     this.qualification,
//     required this.bookingOpen,
//     required this.consulting,
//     this.departmentInfo,
//     this.hospitalName,
//     this.hospitalAddress,
//     this.hospitalPhone,
//     this.hospitalId,
//   });

//   factory Doctor.fromJson(Map<String, dynamic> json) {
//     return Doctor(
//       id: json['_id'] ?? '',
//       name: json['name'] ?? '',
//       specialty: json['specialty'] ?? '',
//       qualification: json['qualification'],
//       bookingOpen: json['bookingOpen'] ?? false,
//       consulting: (json['consulting'] as List? ?? [])
//           .map((consultingJson) => ConsultingDay.fromJson(consultingJson))
//           .toList(),
//       departmentInfo: json['department_info'],
//     );
//   }

//   Doctor copyWith({
//     String? hospitalName,
//     String? hospitalAddress,
//     String? hospitalPhone,
//     String? hospitalId,
//   }) {
//     return Doctor(
//       id: id,
//       name: name,
//       specialty: specialty,
//       qualification: qualification,
//       bookingOpen: bookingOpen,
//       consulting: consulting,
//       departmentInfo: departmentInfo,
//       hospitalName: hospitalName ?? this.hospitalName,
//       hospitalAddress: hospitalAddress ?? this.hospitalAddress,
//       hospitalPhone: hospitalPhone ?? this.hospitalPhone,
//       hospitalId: hospitalId ?? this.hospitalId,
//     );
//   }
// }

// class ConsultingDay {
//   final String day;
//   final List<Session> sessions;
//   final String id;

//   ConsultingDay({
//     required this.day,
//     required this.sessions,
//     required this.id,
//   });

//   factory ConsultingDay.fromJson(Map<String, dynamic> json) {
//     return ConsultingDay(
//       day: json['day'] ?? '',
//       sessions: (json['sessions'] as List? ?? [])
//           .map((sessionJson) => Session.fromJson(sessionJson))
//           .toList(),
//       id: json['_id'] ?? '',
//     );
//   }
// }

// class Session {
//   final String startTime;
//   final String endTime;
//   final String id;

//   Session({
//     required this.startTime,
//     required this.endTime,
//     required this.id,
//   });

//   factory Session.fromJson(Map<String, dynamic> json) {
//     return Session(
//       startTime: json['start_time'] ?? '',
//       endTime: json['end_time'] ?? '',
//       id: json['_id'] ?? '',
//     );
//   }
// }




class Doctor {
  final int id;
  final int hospitalId;
  final String firstName;
  final String lastName;
  final String displayName;
  final String department;
  final String specialist;
  final String qualification;
  final String phone;
  final String email;
  final String fees;
  final String gender;
  final DateTime? dob;
  final List<String> knowLanguages;
  final Address address;
  final ConsultingTime consulting;
  final OutDoorConsulting? outDoorConsulting;
  final bool bookingOpen;
  final DateTime joiningDate;
  final int todayBookingAcceptCount;
  final int roleId;
  final bool isActive;
  final bool isDelete;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  
  // UI-ന് വേണ്ടി additional fields
  String? hospitalName;
  String? hospitalAddress;
  String? hospitalPhone;

  Doctor({
    required this.id,
    required this.hospitalId,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.department,
    required this.specialist,
    required this.qualification,
    required this.phone,
    required this.email,
    required this.fees,
    required this.gender,
    this.dob,
    required this.knowLanguages,
    required this.address,
    required this.consulting,
    this.outDoorConsulting,
    required this.bookingOpen,
    required this.joiningDate,
    required this.todayBookingAcceptCount,
    required this.roleId,
    required this.isActive,
    required this.isDelete,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.hospitalName,
    this.hospitalAddress,
    this.hospitalPhone,
  });

  // Helper getters for UI
  String get fullName => displayName.isNotEmpty ? displayName : "$firstName $lastName";
  String get name => fullName;
  String get specialty => specialist;

  // JSON to Doctor object
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? 0,
      hospitalId: json['hospitalId'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      displayName: json['displayName'] ?? '',
      department: json['department'] ?? '',
      specialist: json['specialist'] ?? '',
      qualification: json['qualification'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      fees: json['fees']?.toString() ?? '0',
      gender: json['gender'] ?? '',
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      knowLanguages: (json['knowLanguages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      address: Address.fromJson(json['address'] ?? {}),
      consulting: ConsultingTime.fromJson(json['consulting'] ?? {}),
      outDoorConsulting: json['outDoorConsulting'] != null 
          ? OutDoorConsulting.fromJson(json['outDoorConsulting']) 
          : null,
      bookingOpen: json['bookingOpen'] ?? false,
      joiningDate: json['joiningDate'] != null 
          ? DateTime.parse(json['joiningDate']) 
          : DateTime.now(),
      todayBookingAcceptCount: json['todayBookingAcceptCount'] ?? 0,
      roleId: json['roleId'] ?? 0,
      isActive: json['isActive'] ?? true,
      isDelete: json['isDelete'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  get doctors => null;

  // Copy with method for adding hospital info
  Doctor copyWith({
    String? hospitalName,
    String? hospitalAddress,
    String? hospitalPhone,
  }) {
    return Doctor(
      id: id,
      hospitalId: hospitalId,
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      department: department,
      specialist: specialist,
      qualification: qualification,
      phone: phone,
      email: email,
      fees: fees,
      gender: gender,
      dob: dob,
      knowLanguages: knowLanguages,
      address: address,
      consulting: consulting,
      outDoorConsulting: outDoorConsulting,
      bookingOpen: bookingOpen,
      joiningDate: joiningDate,
      todayBookingAcceptCount: todayBookingAcceptCount,
      roleId: roleId,
      isActive: isActive,
      isDelete: isDelete,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      hospitalPhone: hospitalPhone ?? this.hospitalPhone,
    );
  }
}

// Address model
class Address {
  final String place;
  final String state;
  final String country;
  final int pincode;
  final String district;

  Address({
    required this.place,
    required this.state,
    required this.country,
    required this.pincode,
    required this.district,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      place: json['place'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? 0,
      district: json['district'] ?? '',
    );
  }
  
  String get fullAddress => "$place, $district, $state, $country - $pincode";
}

// Consulting time model
class ConsultingTime {
  final Session? morningSession;
  final Session? eveningSession;

  ConsultingTime({
    this.morningSession,
    this.eveningSession,
  });

  factory ConsultingTime.fromJson(Map<String, dynamic> json) {
    return ConsultingTime(
      morningSession: json['morning_session'] != null 
          ? Session.fromJson(json['morning_session']) 
          : null,
      eveningSession: json['evening_session'] != null 
          ? Session.fromJson(json['evening_session']) 
          : null,
    );
  }
  
  // For UI display
  List<ConsultingSlot> getAvailableSlots() {
    List<ConsultingSlot> slots = [];
    
    if (morningSession != null) {
      slots.add(ConsultingSlot(
        title: "Morning Session",
        time: "${morningSession!.open} - ${morningSession!.close}",
      ));
    }
    
    if (eveningSession != null) {
      slots.add(ConsultingSlot(
        title: "Evening Session",
        time: "${eveningSession!.open} - ${eveningSession!.close}",
      ));
    }
    
    return slots;
  }

  any(bool Function(day) param0) {}
}

class day {
}

// Session model
class Session {
  final String open;
  final String close;

  Session({
    required this.open,
    required this.close,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      open: json['open']?.toString() ?? '',
      close: json['close']?.toString() ?? '',
    );
  }
  
  String get range => "$open - $close";
}

// Outdoor consulting model
class OutDoorConsulting {
  final TimeSlot time;
  final String place;

  OutDoorConsulting({
    required this.time,
    required this.place,
  });

  factory OutDoorConsulting.fromJson(Map<String, dynamic> json) {
    return OutDoorConsulting(
      time: TimeSlot.fromJson(json['time'] ?? {}),
      place: json['place'] ?? '',
    );
  }
}

// Time slot model
class TimeSlot {
  final String open;
  final String close;

  TimeSlot({
    required this.open,
    required this.close,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      open: json['open']?.toString() ?? '',
      close: json['close']?.toString() ?? '',
    );
  }
  
  String get range => "$open - $close";
}

// UI Helper class
class ConsultingSlot {
  final String title;
  final String time;
  
  ConsultingSlot({
    required this.title,
    required this.time,
  });
}