class BloodCompatibility {
  final List<String> canDonateTo;
  final List<String> canReceiveFrom;
  final String tag;

  const BloodCompatibility({
    required this.canDonateTo,
    required this.canReceiveFrom,
    required this.tag,
  });

  static const List<String> allBloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  static const Map<String, BloodCompatibility> compatibilityMap = {
    'O-': BloodCompatibility(
      canDonateTo: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
      canReceiveFrom: ['O-'],
      tag: '🌟 Universal Donor',
    ),
    'O+': BloodCompatibility(
      canDonateTo: ['O+', 'A+', 'B+', 'AB+'],
      canReceiveFrom: ['O+', 'O-'],
      tag: 'Most Needed',
    ),
    'A-': BloodCompatibility(
      canDonateTo: ['A-', 'A+', 'AB-', 'AB+'],
      canReceiveFrom: ['A-', 'O-'],
      tag: 'Rare Blood Group',
    ),
    'A+': BloodCompatibility(
      canDonateTo: ['A+', 'AB+'],
      canReceiveFrom: ['A+', 'A-', 'O+', 'O-'],
      tag: 'High Demand',
    ),
    'B-': BloodCompatibility(
      canDonateTo: ['B-', 'B+', 'AB-', 'AB+'],
      canReceiveFrom: ['B-', 'O-'],
      tag: 'Rare Blood Group',
    ),
    'B+': BloodCompatibility(
      canDonateTo: ['B+', 'AB+'],
      canReceiveFrom: ['B+', 'B-', 'O+', 'O-'],
      tag: 'Common in South Asia',
    ),
    'AB-': BloodCompatibility(
      canDonateTo: ['AB-', 'AB+'],
      canReceiveFrom: ['AB-', 'A-', 'B-', 'O-'],
      tag: 'Rarest Blood Group',
    ),
    'AB+': BloodCompatibility(
      canDonateTo: ['AB+'],
      canReceiveFrom: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
      tag: '🌟 Universal Recipient',
    ),
  };

  static BloodCompatibility? getFor(String group) => compatibilityMap[group];
}
