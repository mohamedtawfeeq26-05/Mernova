class BloodRequestModel {
  final String id;
  final String requesterId;
  final String? requesterName;
  final String? requesterPhone;
  final String? requesterEmail;
  final String patientName;
  final String hospitalName;
  final String bloodGroup;
  final int unitsRequired;
  final String urgency; // 'Normal', 'Emergency', 'Critical'
  final String city;
  final String address;
  final String contactPhone;
  final String? notes;
  final String status; // 'Pending', 'Accepted', 'Fulfilled', 'Cancelled'
  final Map<String, dynamic>? acceptedBy;
  final DateTime? acceptedAt;
  final DateTime? createdAt;

  BloodRequestModel({
    required this.id,
    required this.requesterId,
    this.requesterName,
    this.requesterPhone,
    this.requesterEmail,
    required this.patientName,
    required this.hospitalName,
    required this.bloodGroup,
    required this.unitsRequired,
    required this.urgency,
    required this.city,
    required this.address,
    required this.contactPhone,
    this.notes,
    required this.status,
    this.acceptedBy,
    this.acceptedAt,
    this.createdAt,
  });

  bool get isEmergency => urgency == 'Emergency' || urgency == 'Critical';
  bool get isAccepted => status == 'Accepted';
  bool get isFulfilled => status == 'Fulfilled';
  bool get isPending => status == 'Pending';

  String? get acceptedByName {
    if (acceptedBy != null && acceptedBy!['name'] != null) {
      return acceptedBy!['name'].toString();
    }
    return null;
  }

  String? get acceptedByBloodGroup {
    if (acceptedBy != null && acceptedBy!['bloodGroup'] != null) {
      return acceptedBy!['bloodGroup'].toString();
    }
    return null;
  }

  String? get acceptedByPhone {
    if (acceptedBy != null && acceptedBy!['phone'] != null) {
      return acceptedBy!['phone'].toString();
    }
    return null;
  }

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    String reqId = '';
    String? reqName;
    String? reqPhone;
    String? reqEmail;

    if (json['requester'] is Map<String, dynamic>) {
      final reqMap = json['requester'] as Map<String, dynamic>;
      reqId = (reqMap['_id'] ?? reqMap['id'] ?? '').toString();
      reqName = reqMap['name'];
      reqPhone = reqMap['phone'];
      reqEmail = reqMap['email'];
    } else if (json['requester'] != null) {
      reqId = json['requester'].toString();
    }

    Map<String, dynamic>? acceptedMap;
    if (json['acceptedBy'] is Map<String, dynamic>) {
      acceptedMap = json['acceptedBy'] as Map<String, dynamic>;
    }

    return BloodRequestModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      requesterId: reqId,
      requesterName: reqName,
      requesterPhone: reqPhone,
      requesterEmail: reqEmail,
      patientName: json['patientName'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      unitsRequired: json['unitsRequired'] is num
          ? (json['unitsRequired'] as num).toInt()
          : (int.tryParse(json['unitsRequired']?.toString() ?? '1') ?? 1),
      urgency: json['urgency'] ?? 'Normal',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      notes: json['notes'],
      status: json['status'] ?? 'Pending',
      acceptedBy: acceptedMap,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'requester': requesterId,
      'patientName': patientName,
      'hospitalName': hospitalName,
      'bloodGroup': bloodGroup,
      'unitsRequired': unitsRequired,
      'urgency': urgency,
      'city': city,
      'address': address,
      'contactPhone': contactPhone,
      'notes': notes,
      'status': status,
      'acceptedBy': acceptedBy,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
