class EmergencyContact {
  const EmergencyContact({
    this.id,
    required this.contactName,
    required this.relationship,
    required this.phoneNumber,
    this.isPrimary = true,
  });

  final String? id;
  final String contactName;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'] as String?,
        contactName: json['contact_name'] as String? ?? '',
        relationship: json['relationship'] as String? ?? '',
        phoneNumber: json['phone_number'] as String? ?? '',
        isPrimary: json['is_primary'] as bool? ?? true,
      );
}
