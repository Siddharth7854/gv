class Grievance {
  final int? grievanceId;
  final String? grievanceNumber;
  final int citizenId;
  final int categoryId;
  final String title;
  final String description;
  final String priority;
  final String urgency;
  final String status;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationAddress;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? assignedTo;
  final String? resolutionNotes;
  final String? categoryName;

  const Grievance({
    this.grievanceId,
    this.grievanceNumber,
    required this.citizenId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.priority,
    required this.urgency,
    this.status = 'Submitted',
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
    required this.submittedAt,
    this.updatedAt,
    this.resolvedAt,
    this.assignedTo,
    this.resolutionNotes,
    this.categoryName,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      grievanceId: json['grievance_id'] as int?,
      grievanceNumber: json['grievance_number'] as String?,
      citizenId: json['citizen_id'] as int,
      categoryId: json['category_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
      urgency: json['urgency'] as String,
      status: json['status'] as String? ?? 'Submitted',
      locationLatitude: json['location_latitude']?.toDouble(),
      locationLongitude: json['location_longitude']?.toDouble(),
      locationAddress: json['location_address'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      assignedTo: json['assigned_to'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      categoryName: json['category_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grievance_id': grievanceId,
      'grievance_number': grievanceNumber,
      'citizen_id': citizenId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'priority': priority,
      'urgency': urgency,
      'status': status,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'location_address': locationAddress,
      'submitted_at': submittedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'assigned_to': assignedTo,
      'resolution_notes': resolutionNotes,
      'category_name': categoryName,
    };
  }

  Grievance copyWith({
    int? grievanceId,
    String? grievanceNumber,
    int? citizenId,
    int? categoryId,
    String? title,
    String? description,
    String? priority,
    String? urgency,
    String? status,
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? assignedTo,
    String? resolutionNotes,
    String? categoryName,
  }) {
    return Grievance(
      grievanceId: grievanceId ?? this.grievanceId,
      grievanceNumber: grievanceNumber ?? this.grievanceNumber,
      citizenId: citizenId ?? this.citizenId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationAddress: locationAddress ?? this.locationAddress,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Grievance &&
        other.grievanceId == grievanceId &&
        other.grievanceNumber == grievanceNumber &&
        other.citizenId == citizenId &&
        other.categoryId == categoryId &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.urgency == urgency &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      grievanceId,
      grievanceNumber,
      citizenId,
      categoryId,
      title,
      description,
      priority,
      urgency,
      status,
    );
  }

  @override
  String toString() {
    return 'Grievance(grievanceId: $grievanceId, grievanceNumber: $grievanceNumber, title: $title, status: $status)';
  }
}
