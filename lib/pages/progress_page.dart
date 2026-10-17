import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../models/activity.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/activity_icon.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  int _selectedPeriod = 0;

  final List<String> _periods = [
    '7 Hari',
    '30 Hari',
    'Semua',
  ];

  @override
  void initState() {
    super.initState();

    AppState.instance.addListener(_refresh);

    if (AppState.instance.activities.isEmpty &&
        !AppState.instance.isLoadingActivities) {
      _loadActivities();
    }
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadActivities() async {
    try {
      await AppState.instance.loadActivities();
    } catch (_) {
      // Error ditampilkan melalui AppState.
    }
  }

  List<Activity> _filteredActivities(List<Activity> activities) {
    if (_selectedPeriod == 2) {
      return activities;
    }

    final now = DateTime.now();
    final startDate = now.subtract(
      Duration(days: _selectedPeriod == 0 ? 7 : 30),
    );

    return activities.where((activity) {
      return !activity.date.isBefore(startDate) &&
          !activity.date.isAfter(now);
    }).toList();
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}j ${remainingMinutes}m';
    }

    return '${minutes}m';
  }

  String _formatPace(double distance, int minutes) {
    if (distance <= 0 || minutes <= 0) {
      return '--:--';
    }

    final secondsPerKm = (minutes * 60 / distance).round();
    final paceMinutes = secondsPerKm ~/ 60;
    final paceSeconds = secondsPerKm % 60;

    return '$paceMinutes:${paceSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final allActivities = app.activities;
    final activities = _filteredActivities(allActivities);

    final distance = activities.fold<double>(
      0,
      (sum, activity) => sum + activity.distanceKm,
    );

    final minutes = activities.fold<int>(
      0,
      (sum, activity) => sum + activity.durationMinutes,
    );

    final sortedActivities = [...activities]
      ..sort((a, b) => a.date.compareTo(b.date));

    final chartActivities = sortedActivities.length > 7
        ? sortedActivities.sublist(sortedActivities.length - 7)
        : sortedActivities;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang statistik',
            onPressed: app.isLoadingActivities ? null : _loadActivities,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivities,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Text(
              'Perkembanganmu',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sedikit demi sedikit, jadi lebih kuat.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),

            if (app.isLoadingActivities && allActivities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (app.activitiesError != null &&
                allActivities.isEmpty)
              _errorCard(app.activitiesError!)
            else ...[
              // Kartu statistik
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.route_rounded,
                      label: 'Total jarak',
                      value: '${distance.toStringAsFixed(2)} km',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.timer_outlined,
                      label: 'Durasi',
                      value: _formatDuration(minutes),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.fitness_center_rounded,
                      label: 'Aktivitas',
                      value: '${activities.length} sesi',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.speed_rounded,
                      label: 'Pace rata-rata',
                      value: '${_formatPace(distance, minutes)}/km',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Filter periode
              const Text(
                'Performa aktivitas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pantau jarak dari sesi olahragamu.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: List.generate(_periods.length, (index) {
                  final selected = _selectedPeriod == index;

                  return ChoiceChip(
                    label: Text(_periods[index]),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedPeriod = index;
                      });
                    },
                    selectedColor: kOrange.withValues(alpha: .18),
                    side: BorderSide(
                      color: selected ? kOrange : Colors.black12,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? kInk : Colors.black54,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 14),

              // Grafik garis
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: .06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .035),
                      blurRadius: 20,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jarak per aktivitas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _selectedPeriod == 0
                          ? '7 hari terakhir'
                          : _selectedPeriod == 1
                              ? '30 hari terakhir'
                              : 'Semua aktivitas',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (chartActivities.isEmpty)
                      const SizedBox(
                        height: 180,
                        child: Center(
                          child: Text(
                            'Belum ada aktivitas pada periode ini.\n'
                            'Yuk, mulai bergerak!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              height: 1.6,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 170,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _LineChartPainter(
                            values: chartActivities
                                .map((activity) => activity.distanceKm)
                                .toList(),
                            lineColor: kOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Label tanggal aktivitas
                      Row(
                        children: chartActivities.map((activity) {
                          final date = activity.date;
                          final label =
                              '${date.day}/${date.month}';

                          return Expanded(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kOrange.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insights_rounded,
                              color: kOrange,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Total ${distance.toStringAsFixed(2)} km '
                                'dalam ${activities.length} aktivitas.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Riwayat aktivitas
              const Text(
                'Riwayat aktivitas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              if (activities.isEmpty)
                const EmptyState(
                  message:
                      'Belum ada aktivitas pada periode ini. '
                      'Coba pilih periode lain atau mulai berolahraga.',
                )
              else
                ...activities.reversed.take(5).map((activity) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kOrange.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                            getActivityIcon(activity.type),
                          color: kOrange,
                        ),
                      ),
                      title: Text(
                        activity.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${activity.date.day.toString().padLeft(2, '0')}/'
                        '${activity.date.month.toString().padLeft(2, '0')}/'
                        '${activity.date.year} • '
                        '${activity.durationMinutes} menit',
                      ),
                      trailing: Text(
                        '${activity.distanceKm.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 8),
              const Text(
                'Data statistik berasal dari aktivitas akun yang '
                'dimuat dari server.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 36,
            ),
            const SizedBox(height: 10),
            const Text(
              'Statistik belum dapat dimuat dari server.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _loadActivities,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.lineColor,
  });

  final List<double> values;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const leftPadding = 8.0;
    const rightPadding = 8.0;
    const topPadding = 20.0;
    const bottomPadding = 18.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final maxValue = math.max(
      1.0,
      values.fold<double>(
        0,
        (maximum, value) => math.max(maximum, value),
      ) * 1.2,
    );

    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + chartWidth * i / (values.length - 1);

      final y = topPadding +
          chartHeight * (1 - values[i] / maxValue);

      points.add(Offset(x, y));
    }

    // Garis horizontal sebagai panduan membaca grafik.
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: .07)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = topPadding + chartHeight * i / 3;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    if (points.length == 1) {
      final pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(points.first, 5, pointPaint);
      return;
    }

    // Jalur garis yang lebih halus.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      final controlX = (current.dx + next.dx) / 2;

      linePath.cubicTo(
        controlX,
        current.dy,
        controlX,
        next.dy,
        next.dx,
        next.dy,
      );
    }

    // Area gradasi di bawah garis.
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height - bottomPadding)
      ..lineTo(points.first.dx, size.height - bottomPadding)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: .28),
          lineColor.withValues(alpha: .01),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          topPadding,
          size.width,
          chartHeight,
        ),
      );

    canvas.drawPath(fillPath, fillPaint);

    // Garis utama.
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Titik aktivitas dengan lingkaran putih di tengah.
    for (final point in points) {
      canvas.drawCircle(
        point,
        5.5,
        Paint()..color = lineColor,
      );

      canvas.drawCircle(
        point,
        2.3,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor;
  }
}
