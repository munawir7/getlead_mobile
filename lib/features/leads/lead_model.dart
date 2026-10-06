class LeadModel {
  const LeadModel({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumbers = const [],
    this.source,
    this.status,
    this.purposes = const [],
    this.score = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? email;
  final List<String> phoneNumbers;
  final LeadSource? source;
  final LeadStatus? status;
  final List<String> purposes;
  final num score;
  final DateTime? createdAt;

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: _stringValue(json['id']),
      name: _stringValue(
        json['name'],
        fallback: 'Unnamed Lead',
      ),
      email: _nullableString(json['email']),
      phoneNumbers: _parseStringList(
        json['phone_numbers'] ?? json['phoneNumbers'],
      ),
      source: _parseSource(json['source']),
      status: _parseStatus(json['status']),
      purposes: _parseStringList(json['purposes']),
      score: _parseNumber(json['score']),
      createdAt: _parseDateTime(
        json['created_at'] ?? json['createdAt'] ?? json['time'],
      ),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.isNegative || diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    return '${(diff.inDays / 30).floor()}mo';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  static String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) {
      return [];
    }

    if (value is List) {
      return value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item['name']?.toString() ?? '';
            }

            return item.toString();
          })
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String) {
      final result = value.trim();

      if (result.isEmpty) {
        return [];
      }

      return [result];
    }

    return [];
  }

  static LeadSource? _parseSource(dynamic value) {
    if (value is Map<String, dynamic>) {
      return LeadSource.fromJson(value);
    }

    return null;
  }

  static LeadStatus? _parseStatus(dynamic value) {
    if (value is Map<String, dynamic>) {
      return LeadStatus.fromJson(value);
    }

    return null;
  }

  static num _parseNumber(dynamic value) {
    if (value is num) {
      return value;
    }

    if (value is String) {
      return num.tryParse(value) ?? 0;
    }

    return 0;
  }
}

class LeadSource {
  const LeadSource({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory LeadSource.fromJson(Map<String, dynamic> json) {
    return LeadSource(
      id: _stringValue(json['id']),
      name: _stringValue(
        json['name'],
        fallback: 'Unknown',
      ),
    );
  }

  static String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }
}

class LeadStatus {
  const LeadStatus({
    required this.id,
    required this.name,
    this.slug,
    this.color,
  });

  final String id;
  final String name;
  final String? slug;
  final String? color;

  factory LeadStatus.fromJson(Map<String, dynamic> json) {
    return LeadStatus(
      id: _stringValue(json['id']),
      name: _stringValue(
        json['name'],
        fallback: 'Unknown',
      ),
      slug: _nullableString(json['slug']),
      color: _nullableString(json['color']),
    );
  }

  static String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }
}