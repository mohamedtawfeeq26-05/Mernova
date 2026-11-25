class AdminStatsModel {
  final int totalDonors;
  final int availableDonors;
  final int totalRequesters;
  final int totalRequests;
  final int pendingRequests;
  final int emergencyRequests;
  final int acceptedRequests;
  final int fulfilledRequests;

  AdminStatsModel({
    required this.totalDonors,
    required this.availableDonors,
    required this.totalRequesters,
    required this.totalRequests,
    required this.pendingRequests,
    required this.emergencyRequests,
    required this.acceptedRequests,
    required this.fulfilledRequests,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '0') ?? 0;
    }

    return AdminStatsModel(
      totalDonors: toInt(json['totalDonors']),
      availableDonors: toInt(json['availableDonors']),
      totalRequesters: toInt(json['totalRequesters']),
      totalRequests: toInt(json['totalRequests']),
      pendingRequests: toInt(json['pendingRequests']),
      emergencyRequests: toInt(json['emergencyRequests']),
      acceptedRequests: toInt(json['acceptedRequests']),
      fulfilledRequests: toInt(json['fulfilledRequests']),
    );
  }
}
