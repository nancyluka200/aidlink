class ApplicationModel {
  final String programId;
  final String programName;
  final String status;
  final DateTime appliedAt;
  final DateTime updatedAt;

  ApplicationModel({
    required this.programId,
    required this.programName,
    required this.status,
    required this.appliedAt,
    required this.updatedAt,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      programId: json['programId']?.toString() ?? '',
      programName: json['programName'] ?? 'Unknown Program',
      status: json['status'] ?? 'Pending',
      appliedAt: DateTime.tryParse(json['appliedAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}