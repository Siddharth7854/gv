class Grievance {
  final int? grievanceId;
  final String? grievanceNumber;
  final int citizenId;
  final int? departmentId;
  final int categoryId;
  final int? subcategoryId;
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
  final DateTime createdAt;
  final bool isSynced;
  final String? categoryName;
  final String? subcategoryName;
  final String? departmentName;

  const Grievance({
    this.grievanceId,
    this.grievanceNumber,
    required this.citizenId,
    this.departmentId,
    required this.categoryId,
    this.subcategoryId,
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
    required this.createdAt,
    this.isSynced = false,
    this.categoryName,
    this.subcategoryName,
    this.departmentName,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      grievanceId: json['grievanceId'] as int?,
      grievanceNumber: json['grievanceNumber'] as String?,
      citizenId: json['citizenId'] as int,
      departmentId: json['departmentId'] as int?,
      categoryId: json['categoryId'] as int,
      subcategoryId: json['subcategoryId'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
      urgency: json['urgency'] as String,
      status: json['status'] as String? ?? 'Submitted',
      locationLatitude: json['locationLatitude'] as double?,
      locationLongitude: json['locationLongitude'] as double?,
      locationAddress: json['locationAddress'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      assignedTo: json['assignedTo'] as String?,
      resolutionNotes: json['resolutionNotes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isSynced: json['isSynced'] as bool? ?? false,
      categoryName: json['categoryName'] as String?,
      subcategoryName: json['subcategoryName'] as String?,
      departmentName: json['departmentName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grievanceId': grievanceId,
      'grievanceNumber': grievanceNumber,
      'citizenId': citizenId,
      'departmentId': departmentId,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'title': title,
      'description': description,
      'priority': priority,
      'urgency': urgency,
      'status': status,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'locationAddress': locationAddress,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'resolutionNotes': resolutionNotes,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced,
      'categoryName': categoryName,
      'subcategoryName': subcategoryName,
      'departmentName': departmentName,
    };
  }

  Grievance copyWith({
    int? grievanceId,
    String? grievanceNumber,
    int? citizenId,
    int? departmentId,
    int? categoryId,
    int? subcategoryId,
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
    DateTime? createdAt,
    bool? isSynced,
    String? categoryName,
    String? subcategoryName,
    String? departmentName,
  }) {
    return Grievance(
      grievanceId: grievanceId ?? this.grievanceId,
      grievanceNumber: grievanceNumber ?? this.grievanceNumber,
      citizenId: citizenId ?? this.citizenId,
      departmentId: departmentId ?? this.departmentId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
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
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      categoryName: categoryName ?? this.categoryName,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      departmentName: departmentName ?? this.departmentName,
    );
  }
}

class Category {
  final int categoryId;
  final int? departmentId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const Category({
    required this.categoryId,
    this.departmentId,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'] as int,
      departmentId: json['departmentId'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'departmentId': departmentId,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Subcategory {
  final int subcategoryId;
  final int categoryId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const Subcategory({
    required this.subcategoryId,
    required this.categoryId,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      subcategoryId: json['subcategoryId'] as int,
      categoryId: json['categoryId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subcategoryId': subcategoryId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Citizen {
  final int citizenId;
  final String citizenNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? address;
  final DateTime createdAt;
  final bool isActive;

  const Citizen({
    required this.citizenId,
    required this.citizenNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.address,
    required this.createdAt,
    this.isActive = true,
  });

  factory Citizen.fromJson(Map<String, dynamic> json) {
    return Citizen(
      citizenId: json['citizenId'] as int,
      citizenNumber: json['citizenNumber'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'citizenId': citizenId,
      'citizenNumber': citizenNumber,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  String get fullName => '$firstName $lastName';
}

class MediaAttachment {
  final int attachmentId;
  final int grievanceId;
  final String fileName;
  final String fileType;
  final String filePath;
  final int fileSize;
  final DateTime uploadedAt;

  const MediaAttachment({
    required this.attachmentId,
    required this.grievanceId,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      attachmentId: json['attachmentId'] as int,
      grievanceId: json['grievanceId'] as int,
      fileName: json['fileName'] as String,
      fileType: json['fileType'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attachmentId': attachmentId,
      'grievanceId': grievanceId,
      'fileName': fileName,
      'fileType': fileType,
      'filePath': filePath,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
