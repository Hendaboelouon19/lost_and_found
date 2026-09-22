enum ReportType { lost, found }

extension ReportTypeExtension on ReportType {
  String get label {
    switch (this) {
      case ReportType.lost:
        return 'Lost';
      case ReportType.found:
        return 'Found';
    }
  }

  bool get isLost => this == ReportType.lost;
}

class LostFoundReport {
  const LostFoundReport({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.location,
    required this.time,
    required this.description,
    this.photoUrl,
    this.matchProbability,
    this.userId,
  });

  final String id;
  final String title;
  final ReportType type;
  final String category;
  final String location;
  final String time;
  final String description;
  final String? photoUrl;
  final double? matchProbability;
  final String? userId;

  factory LostFoundReport.fromMap(Map<String, dynamic> map) {
    return LostFoundReport(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      type: _reportTypeFromString(map['type']?.toString() ?? 'Lost'),
      category: map['category']?.toString() ?? 'General',
      location: map['location']?.toString() ?? 'Unknown',
      time: map['time']?.toString() ?? 'Unknown time',
      description: map['description']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString(),
      matchProbability: map['matchProbability'] is num ? (map['matchProbability'] as num).toDouble() : null,
      userId: map['userId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.label,
      'category': category,
      'location': location,
      'time': time,
      'description': description,
      'photoUrl': photoUrl,
      'matchProbability': matchProbability,
      'userId': userId,
    };
  }

  static ReportType _reportTypeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'found':
        return ReportType.found;
      case 'lost':
      default:
        return ReportType.lost;
    }
  }

  static double calculateMatchProbability(LostFoundReport lostReport, LostFoundReport foundReport) {
    if (lostReport.type == foundReport.type) {
      return 0;
    }

    final titleA = lostReport.title.trim().toLowerCase();
    final titleB = foundReport.title.trim().toLowerCase();
    final categoryA = lostReport.category.trim().toLowerCase();
    final categoryB = foundReport.category.trim().toLowerCase();
    final locationA = lostReport.location.trim().toLowerCase();
    final locationB = foundReport.location.trim().toLowerCase();

    double score = 0;

    if (titleA == titleB) {
      score += 40;
    }

    if (categoryA == categoryB) {
      score += 20;
    }

    if (locationA == locationB) {
      score += 25;
    }

    final sameDay = _isSameDayTag(lostReport.time, foundReport.time);
    if (sameDay) {
      score += 10;
    }

    final descriptionSimilarity = _descriptionSimilarity(lostReport.description, foundReport.description);
    score += descriptionSimilarity;

    return score.clamp(0, 100);
  }

  static double _descriptionSimilarity(String left, String right) {
    final wordsLeft = left.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final wordsRight = right.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();

    if (wordsLeft.isEmpty || wordsRight.isEmpty) {
      return 0;
    }

    final overlap = wordsLeft.intersection(wordsRight).length;
    final total = wordsLeft.union(wordsRight).length;

    if (total == 0) {
      return 0;
    }

    return (overlap / total) * 5;
  }

  static bool _isSameDayTag(String left, String right) {
    final normalizedLeft = left.toLowerCase();
    final normalizedRight = right.toLowerCase();

    return normalizedLeft.contains('today') && normalizedRight.contains('today') ||
        normalizedLeft.contains('yesterday') && normalizedRight.contains('yesterday') ||
        normalizedLeft.contains('this morning') && normalizedRight.contains('this morning') ||
        normalizedLeft.contains('this afternoon') && normalizedRight.contains('this afternoon');
  }
}
