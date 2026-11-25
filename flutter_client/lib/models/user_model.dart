class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'donor', 'requester', 'admin'
  final String? bloodGroup;
  final int? age;
  final String? gender;
  final String? city;
  final String? address;
  final String? pincode;
  final String availability; // 'Available', 'Unavailable'
  final DateTime? lastDonationDate;
  final DateTime? nextEligibleDate;
  final int totalDonations;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.bloodGroup,
    this.age,
    this.gender,
    this.city,
    this.address,
    this.pincode,
    this.availability = 'Available',
    this.lastDonationDate,
    this.nextEligibleDate,
    this.totalDonations = 0,
    this.createdAt,
  });

  bool get isDonor => role == 'donor';
  bool get isRequester => role == 'requester';
  bool get isAdmin => role == 'admin';
  bool get isAvailable => availability == 'Available';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'donor',
      bloodGroup: json['bloodGroup'],
      age: json['age'] is num ? (json['age'] as num).toInt() : (int.tryParse(json['age']?.toString() ?? '')),
      gender: json['gender'],
      city: json['city'],
      address: json['address'],
      pincode: json['pincode'],
      availability: json['availability'] ?? 'Available',
      lastDonationDate: json['lastDonationDate'] != null
          ? DateTime.tryParse(json['lastDonationDate'].toString())
          : null,
      nextEligibleDate: json['nextEligibleDate'] != null
          ? DateTime.tryParse(json['nextEligibleDate'].toString())
          : null,
      totalDonations: json['totalDonations'] is num
          ? (json['totalDonations'] as num).toInt()
          : 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'bloodGroup': bloodGroup,
      'age': age,
      'gender': gender,
      'city': city,
      'address': address,
      'pincode': pincode,
      'availability': availability,
      'lastDonationDate': lastDonationDate?.toIso8601String(),
      'nextEligibleDate': nextEligibleDate?.toIso8601String(),
      'totalDonations': totalDonations,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? city,
    String? address,
    String? pincode,
    String? availability,
    DateTime? lastDonationDate,
    DateTime? nextEligibleDate,
    int? totalDonations,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      bloodGroup: bloodGroup,
      age: age,
      gender: gender,
      city: city ?? this.city,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      availability: availability ?? this.availability,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      nextEligibleDate: nextEligibleDate ?? this.nextEligibleDate,
      totalDonations: totalDonations ?? this.totalDonations,
      createdAt: createdAt,
    );
  }
}
