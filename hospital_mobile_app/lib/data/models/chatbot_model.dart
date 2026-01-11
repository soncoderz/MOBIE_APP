/// Model for chatbot message
class ChatbotMessageModel {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final ChatbotStructuredData? structuredData;

  ChatbotMessageModel({
    required this.role,
    required this.content,
    required this.timestamp,
    this.structuredData,
  });

  factory ChatbotMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatbotMessageModel(
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      structuredData: json['structuredData'] != null
          ? ChatbotStructuredData.fromJson(json['structuredData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (structuredData != null) 'structuredData': structuredData!.toJson(),
    };
  }

  bool get isUser => role == 'user';
  bool get isBot => role == 'assistant';
}

/// Model for structured data returned by chatbot (lists of doctors, appointments, etc.)
class ChatbotStructuredData {
  final String type; // 'doctors', 'hospitals', 'specialties', 'services', 'appointments'
  final List<dynamic> items;

  ChatbotStructuredData({
    required this.type,
    required this.items,
  });

  factory ChatbotStructuredData.fromJson(Map<String, dynamic> json) {
    return ChatbotStructuredData(
      type: json['type'] ?? '',
      items: json['items'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'items': items,
    };
  }

  bool get hasDoctors => type == 'doctors';
  bool get hasHospitals => type == 'hospitals';
  bool get hasSpecialties => type == 'specialties';
  bool get hasServices => type == 'services';
  bool get hasAppointments => type == 'appointments';
}

/// Response model from chatbot API
class ChatbotResponseModel {
  final bool success;
  final String message;
  final String? intent;
  final ChatbotStructuredData? structuredData;
  final DateTime timestamp;

  ChatbotResponseModel({
    required this.success,
    required this.message,
    this.intent,
    this.structuredData,
    required this.timestamp,
  });

  factory ChatbotResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return ChatbotResponseModel(
      success: json['success'] ?? true,
      message: data['message'] ?? '',
      intent: data['intent'],
      structuredData: data['structuredData'] != null
          ? ChatbotStructuredData.fromJson(data['structuredData'])
          : null,
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Doctor item from chatbot response
class ChatbotDoctorItem {
  final String id;
  final String name;
  final String title;
  final String specialty;
  final String hospital;
  final int experience;
  final double rating;
  final int ratingCount;
  final double consultationFee;
  final bool isAvailable;

  ChatbotDoctorItem({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.hospital,
    required this.experience,
    required this.rating,
    required this.ratingCount,
    required this.consultationFee,
    required this.isAvailable,
  });

  factory ChatbotDoctorItem.fromJson(Map<String, dynamic> json) {
    return ChatbotDoctorItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Không xác định',
      title: json['title'] ?? '',
      specialty: json['specialty'] ?? 'Chưa xác định',
      hospital: json['hospital'] ?? 'Chưa xác định',
      experience: json['experience'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}

/// Hospital item from chatbot response
class ChatbotHospitalItem {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final double rating;
  final bool isMainHospital;
  final List<String> specialties;

  ChatbotHospitalItem({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    required this.rating,
    required this.isMainHospital,
    required this.specialties,
  });

  factory ChatbotHospitalItem.fromJson(Map<String, dynamic> json) {
    return ChatbotHospitalItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      rating: (json['rating'] ?? 0).toDouble(),
      isMainHospital: json['isMainHospital'] ?? false,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Appointment item from chatbot response
class ChatbotAppointmentItem {
  final String id;
  final String bookingCode;
  final DateTime date;
  final Map<String, dynamic>? timeSlot;
  final String status;
  final String doctor;
  final String hospital;
  final String specialty;
  final String? service;
  final double totalAmount;

  ChatbotAppointmentItem({
    required this.id,
    required this.bookingCode,
    required this.date,
    this.timeSlot,
    required this.status,
    required this.doctor,
    required this.hospital,
    required this.specialty,
    this.service,
    required this.totalAmount,
  });

  factory ChatbotAppointmentItem.fromJson(Map<String, dynamic> json) {
    return ChatbotAppointmentItem(
      id: json['id']?.toString() ?? '',
      bookingCode: json['bookingCode'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      timeSlot: json['timeSlot'],
      status: json['status'] ?? 'pending',
      doctor: json['doctor'] ?? 'Không xác định',
      hospital: json['hospital'] ?? 'Không xác định',
      specialty: json['specialty'] ?? 'Không xác định',
      service: json['service'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'pending_payment':
        return 'Chờ thanh toán';
      case 'rescheduled':
        return 'Đã đổi lịch';
      default:
        return status;
    }
  }
}

/// Service item from chatbot response  
class ChatbotServiceItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String specialty;
  final String type;

  ChatbotServiceItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    required this.specialty,
    required this.type,
  });

  factory ChatbotServiceItem.fromJson(Map<String, dynamic> json) {
    return ChatbotServiceItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? 30,
      specialty: json['specialty'] ?? 'Chưa xác định',
      type: json['type'] ?? 'examination',
    );
  }
}

/// Specialty item from chatbot response
class ChatbotSpecialtyItem {
  final String id;
  final String name;
  final String? description;
  final String? icon;

  ChatbotSpecialtyItem({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  factory ChatbotSpecialtyItem.fromJson(Map<String, dynamic> json) {
    return ChatbotSpecialtyItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
    );
  }
}
