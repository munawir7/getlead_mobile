class DealModel {
  const DealModel({
    required this.id,
    required this.name,
    required this.amount,
    this.dealNumber,
    this.currency = 'INR',
    this.leadId,
    this.leadName,
    this.branchId,
    this.branchName,
    this.dealTypeId,
    this.dealTypeName,
    this.dealStatusId,
    this.dealStatusName,
    this.dealStatusColor,
    this.expectedCloseDate,
    this.notes,
    this.assignedToId,
    this.customFields = const {},
  });

  // ============================================================
  // PROPERTIES
  // ============================================================

  final String id;
  final String name;
  final double amount;

  final String? dealNumber;
  final String currency;

  final String? leadId;
  final String? leadName;

  final String? branchId;
  final String? branchName;

  final String? dealTypeId;
  final String? dealTypeName;

  final String? dealStatusId;
  final String? dealStatusName;
  final String? dealStatusColor;

  final String? expectedCloseDate;
  final String? notes;

  final String? assignedToId;

  /// Custom field values associated with this deal.
  ///
  /// Example:
  /// {
  ///   'education': 'Graduate',
  ///   'gender': 'female',
  ///   'age': 25
  /// }
  final Map<String, dynamic> customFields;

  // ============================================================
  // JSON TO MODEL
  // ============================================================

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      id: _stringValue(json['id']) ?? '',
      name: _stringValue(json['name']) ?? '',
      amount: _parseAmount(json['amount']),
      dealNumber: _stringValue(json['deal_number']),
      currency: _stringValue(json['currency']) ?? 'INR',
      leadId: _extractId(json['lead_id']),
      leadName: _extractName(json['lead_name']),
      branchId: _extractId(json['branch_id']),
      branchName: _extractName(json['branch_name']),
      dealTypeId: _extractId(json['deal_type_id']),
      dealTypeName: _extractName(json['deal_type_name']),
      dealStatusId: _extractId(json['deal_status_id']),
      dealStatusName: _extractName(json['deal_status_name']),
      dealStatusColor: _stringValue(json['deal_status_color']),
      expectedCloseDate: _stringValue(
        json['expected_close_date'],
      ),
      notes: _stringValue(json['notes']),
      assignedToId: _extractId(json['assigned_to_id']),
      customFields: _extractCustomFields(json),
    );
  }

  // ============================================================
  // MODEL TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'deal_number': dealNumber,
      'currency': currency,
      'lead_id': leadId,
      'lead_name': leadName,
      'branch_id': branchId,
      'branch_name': branchName,
      'deal_type_id': dealTypeId,
      'deal_type_name': dealTypeName,
      'deal_status_id': dealStatusId,
      'deal_status_name': dealStatusName,
      'deal_status_color': dealStatusColor,
      'expected_close_date': expectedCloseDate,
      'notes': notes,
      'assigned_to_id': assignedToId,
      'custom_fields': customFields,
    };
  }

  // ============================================================
  // EXTRACT CUSTOM FIELDS
  // ============================================================

  static Map<String, dynamic> _extractCustomFields(
    Map<String, dynamic> json,
  ) {
    final result = <String, dynamic>{};

    final rawFields = json['custom_fields'];

    if (rawFields is Map) {
      for (final entry in rawFields.entries) {
        result[entry.key.toString()] = entry.value;
      }

      return result;
    }

    if (rawFields is List) {
      for (final item in rawFields) {
        if (item is! Map) continue;

        final key = _stringValue(
          item['field_key'] ??
              item['key'] ??
              item['name'],
        );

        if (key == null) continue;

        result[key] = item['value'];
      }
    }

    return result;
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  static double _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim()) ?? 0.0;
    }

    return 0.0;
  }

  static String? _stringValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map || value is List) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  static String? _extractId(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      return _stringValue(value['id']);
    }

    return _stringValue(value);
  }

  static String? _extractName(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      return _stringValue(value['name']);
    }

    return _stringValue(value);
  }
}