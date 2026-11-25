class NotificationModel {
  final String id;
  final String recipientId;
  final String type; // 'REQUEST_MATCH', 'EMERGENCY_ALERT', 'REQUEST_ACCEPTED', 'AVAILABILITY_REMINDER', 'STATUS_UPDATE'
  final String title;
  final String message;
  final String? bloodRequestId;
  final bool read;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.bloodRequestId,
    this.read = false,
    this.metadata,
    this.createdAt,
  });

  bool get isEmergency => type == 'EMERGENCY_ALERT';
  bool get isAccepted => type == 'REQUEST_ACCEPTED';
  bool get isReminder => type == 'AVAILABILITY_REMINDER';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String? bReqId;
    if (json['bloodRequest'] is Map<String, dynamic>) {
      bReqId = json['bloodRequest']['_id']?.toString();
    } else if (json['bloodRequest'] != null) {
      bReqId = json['bloodRequest'].toString();
    }

    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      recipientId: (json['recipient'] ?? '').toString(),
      type: json['type'] ?? 'STATUS_UPDATE',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      bloodRequestId: bReqId,
      read: json['read'] == true,
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      id: id,
      recipientId: recipientId,
      type: type,
      title: title,
      message: message,
      bloodRequestId: bloodRequestId,
      read: read ?? this.read,
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}
