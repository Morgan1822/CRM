class DealModel {
  final String id;
  final String title;
  final double value;
  final String currency;
  final String stage; // lead, qualified, proposal, negotiation, won, lost
  final String? contactId;
  final String? contactName;
  final String? notes;
  final DateTime? expectedCloseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  DealModel({
    required this.id,
    required this.title,
    required this.value,
    this.currency = 'INR',
    required this.stage,
    this.contactId,
    this.contactName,
    this.notes,
    this.expectedCloseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Deal',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      stage: json['stage'] as String? ?? 'lead',
      contactId: json['contact_id'] as String?,
      contactName: json['contact'] != null
          ? '${json['contact']['first_name'] ?? ''} ${json['contact']['last_name'] ?? ''}'.trim()
          : null,
      notes: json['notes'] as String?,
      expectedCloseDate: json['expected_close_date'] != null
          ? DateTime.parse(json['expected_close_date'] as String)
          : null,
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
      'title': title,
      'value': value,
      'currency': currency,
      'stage': stage,
      'contact_id': contactId,
      'notes': notes,
      'expected_close_date': expectedCloseDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  DealModel copyWith({
    String? id,
    String? title,
    double? value,
    String? currency,
    String? stage,
    String? contactId,
    String? contactName,
    String? notes,
    DateTime? expectedCloseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DealModel(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      currency: currency ?? this.currency,
      stage: stage ?? this.stage,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      notes: notes ?? this.notes,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
