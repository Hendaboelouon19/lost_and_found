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
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.photoData,
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
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? photoData;
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
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      photoUrl: map['photoUrl']?.toString(),
      photoData: map['photoData']?.toString(),
      matchProbability: map['matchProbability'] is num
          ? (map['matchProbability'] as num).toDouble()
          : null,
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
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'photoData': photoData,
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

  static double calculateMatchProbability(
    LostFoundReport lostReport,
    LostFoundReport foundReport,
  ) {
    if (lostReport.type == foundReport.type) {
      return 0;
    }

    final titleA = _normalize(lostReport.title);
    final titleB = _normalize(foundReport.title);
    final categoryA = _normalize(lostReport.category);
    final categoryB = _normalize(foundReport.category);
    final locationA = _normalizeLocation(lostReport.location);
    final locationB = _normalizeLocation(foundReport.location);

    double score = 0;

    if (titleA == titleB) {
      score += 35;
    } else if (_hasSharedMeaningfulWord(titleA, titleB)) {
      score += 18;
    }

    if (categoryA == categoryB) {
      score += 20;
    }

    if (locationA == locationB) {
      score += 20;
    } else if (_hasSharedMeaningfulWord(locationA, locationB)) {
      score += 10;
    } else if (_coordinatesAreNearby(lostReport, foundReport)) {
      score += 15;
    }

    final timeDifference = _timeDifference(lostReport.time, foundReport.time);
    if (timeDifference != null) {
      if (timeDifference <= const Duration(hours: 2)) {
        score += 15;
      } else if (timeDifference <= const Duration(days: 1)) {
        score += 8;
      }
    } else if (_isSameDayTag(lostReport.time, foundReport.time)) {
      score += 8;
    }

    final descriptionSimilarity = _descriptionSimilarity(
      lostReport.description,
      foundReport.description,
    );
    score += descriptionSimilarity;

    return score.clamp(0, 100);
  }

  static double _descriptionSimilarity(String left, String right) {
    final wordsLeft = _normalize(left)
        .split(RegExp(r'\s+'))
      .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet();
    final wordsRight = _normalize(right)
        .split(RegExp(r'\s+'))
      .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet();

    if (wordsLeft.isEmpty || wordsRight.isEmpty) {
      return 0;
    }

    final overlap = wordsLeft.intersection(wordsRight).length;
    final total = wordsLeft.union(wordsRight).length;

    if (total == 0) {
      return 0;
    }

    return (overlap / total) * 10;
  }

  static double bestMatchProbability(
    LostFoundReport report,
    Iterable<LostFoundReport> reports,
  ) {
    final candidates = reports.where(
      (candidate) =>
          candidate.id != report.id && candidate.type != report.type,
    );

    return candidates
        .map((candidate) => report.type.isLost
            ? calculateMatchProbability(report, candidate)
            : calculateMatchProbability(candidate, report))
        .fold<double>(0, (best, score) => score > best ? score : best);
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeLocation(String value) {
    final withoutCoordinates = value.replaceFirst(
      RegExp(r'\s*\([^)]*\)\s*$'),
      '',
    );
    return _normalize(withoutCoordinates);
  }

  static bool _hasSharedMeaningfulWord(String left, String right) {
    final leftWords = left
        .split(' ')
        .where((word) => word.length > 2 && !_stopWords.contains(word));
    final rightWords = right.split(' ').toSet();
    return leftWords.any(rightWords.contains);
  }

  static bool _coordinatesAreNearby(
    LostFoundReport left,
    LostFoundReport right,
  ) {
    if (left.latitude == null ||
        left.longitude == null ||
        right.latitude == null ||
        right.longitude == null) {
      return false;
    }

    final latitudeDifference = (left.latitude! - right.latitude!).abs();
    final longitudeDifference = (left.longitude! - right.longitude!).abs();
    return latitudeDifference <= 0.002 && longitudeDifference <= 0.002;
  }

  static Duration? _timeDifference(String left, String right) {
    final first = _parseTime(left);
    final second = _parseTime(right);
    if (first == null || second == null) return null;
    return first.difference(second).abs();
  }

  static DateTime? _parseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4}),\s*(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;

    var hour = int.parse(match.group(4)!);
    final isPm = match.group(6)!.toUpperCase() == 'PM';
    if (hour == 12) hour = 0;
    if (isPm) hour += 12;

    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
      hour,
      int.parse(match.group(5)!),
    );
  }

  static const _stopWords = {
    'the', 'and', 'with', 'near', 'found', 'lost', 'item', 'one', 'was', 'this',
  };

  static bool _isSameDayTag(String left, String right) {
    final normalizedLeft = left.toLowerCase();
    final normalizedRight = right.toLowerCase();

    return normalizedLeft.contains('today') &&
            normalizedRight.contains('today') ||
        normalizedLeft.contains('yesterday') &&
            normalizedRight.contains('yesterday') ||
        normalizedLeft.contains('this morning') &&
            normalizedRight.contains('this morning') ||
        normalizedLeft.contains('this afternoon') &&
            normalizedRight.contains('this afternoon');
  }
}
