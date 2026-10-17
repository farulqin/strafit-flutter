class Activity {
  Activity({
    this.id,
    required this.title,
    required this.type,
    required this.distanceKm,
    required this.durationMinutes,
    required this.date,
  });

  final int? id;
  final String title;
  final String type;
  final double distanceKm;
  final int durationMinutes;
  final DateTime date;

  /// Converts an activity returned by Laravel into the UI model.
  factory Activity.fromApi(Map<String, dynamic> json) {
    final sportType = (json['sport_type'] ?? 'running').toString();
    final type = switch (sportType) {
      'running' => 'Lari',
      'walking' => 'Jalan kaki',
      'cycling' => 'Bersepeda',
      _ => sportType,
    };

    final startedAt = json['started_at'] ?? json['created_at'];
    final parsedDate = startedAt == null
        ? DateTime.now()
        : DateTime.tryParse(startedAt.toString()) ?? DateTime.now();

    final distance = json['distance_km'];
    final duration = json['duration_seconds'];

    return Activity(
      id: int.tryParse((json['id'] ?? '').toString()),
      title: (json['title'] ?? '').toString().trim().isEmpty
          ? type
          : json['title'].toString(),
      type: type,
      distanceKm: distance is num
          ? distance.toDouble()
          : double.tryParse(distance?.toString() ?? '') ?? 0,
      durationMinutes: ((duration is num
                  ? duration.toDouble()
                  : double.tryParse(duration?.toString() ?? '') ?? 0) /
              60)
          .round(),
      date: parsedDate.toLocal(),
    );
  }
}