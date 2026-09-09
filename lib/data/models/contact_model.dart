class ContactModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? company;
  final String? jobTitle;
  final String status;
  final String? notes;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.company,
    this.jobTitle,
    this.status = 'lead',
    this.notes,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      jobTitle: json['job_title'] as String?,
      status: json['status'] as String? ?? 'lead',
      notes: json['notes'] as String?,
      assignedTo: json['assigned_to'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'company': company,
      'job_title': jobTitle,
      'status': status,
      'notes': notes,
      'assigned_to': assignedTo,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  ContactModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
    String? status,
    String? notes,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
