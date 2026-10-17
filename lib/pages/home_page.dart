import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../models/activity.dart';
import '../widgets/activity_tile.dart';
import '../widgets/empty_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      await AppState.instance.loadActivities();
    } catch (_) {
      // Pesan error ditampilkan dari AppState.
    }
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<Activity> _filteredActivities(List<Activity> activities) {
    if (_selectedPeriod == 2) {
      return activities;
    }

    final now = DateTime.now();
    final days = _selectedPeriod == 0 ? 7 : 30;
    final startDate = now.subtract(Duration(days: days));

    return activities.where((activity) {
      return !activity.date.isBefore(startDate) &&
          !activity.date.isAfter(now);
    }).toList();
  }

  String _formatPace(double distanceKm, int durationMinutes) {
    if (distanceKm <= 0 || durationMinutes <= 0) {
      return '--:--';
    }

    // Model Activity menyimpan durasi dalam menit.
    final paceSeconds =
        ((durationMinutes * 60) / distanceKm).round();

    final minutes = paceSeconds ~/ 60;
    final seconds = paceSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }

    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final activities = app.activities;
    final count = activities.length;

    final filteredActivities = _filteredActivities(activities);

    final filteredDistance = filteredActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.distanceKm,
    );

    final filteredMinutes = filteredActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.durationMinutes,
    );

    final averagePace = _formatPace(
      filteredDistance,
      filteredMinutes,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              'STRA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.3,
              ),
            ),
            Text(
              'FIT',
              style: TextStyle(
                color: kOrange,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.3,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              tooltip: 'Notifikasi',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Belum ada notifikasi baru.'),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadActivities,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            // SAPAAN
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIAP BERGERAK,',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${app.name}!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Setiap sesi membuatmu lebih kuat.',
                        style: TextStyle(
                          color: Color(0xFF6F7479),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: kInk,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: kOrange,
                    size: 29,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // TOTAL JARAK
            Container(
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF202326),
                    Color(0xFF101112),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -28,
                    top: -34,
                    child: Transform.rotate(
                      angle: -.25,
                      child: Icon(
                        Icons.directions_run_rounded,
                        size: 168,
                        color: Colors.white.withValues(alpha: .055),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: kOrange,
                            size: 9,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'TOTAL JARAK AKTIVITAS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.trending_up_rounded,
                            color: kOrange,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            app.totalDistance.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              height: .98,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(
                              left: 8,
                              bottom: 7,
                            ),
                            child: Text(
                              'KM',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 21),
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: .12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _darkStat(
                              Icons.timer_outlined,
                              '${app.totalMinutes}',
                              'MENIT AKTIF',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 34,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _darkStat(
                              Icons.fitness_center_rounded,
                              '$count',
                              'AKTIVITAS',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // MULAI AKTIVITAS
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: widget.onStart,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 25),
                    SizedBox(width: 8),
                    Text(
                      'MULAI AKTIVITAS',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // DASHBOARD
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Dashboard performa',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Muat ulang',
                  onPressed:
                      app.isLoadingActivities ? null : _loadActivities,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // FILTER PERIODE
            Wrap(
              spacing: 8,
              children: List.generate(_periods.length, (index) {
                return ChoiceChip(
                  label: Text(_periods[index]),
                  selected: _selectedPeriod == index,
                  onSelected: (_) {
                    setState(() {
                      _selectedPeriod = index;
                    });
                  },
                  selectedColor: kOrange.withValues(alpha: .20),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _selectedPeriod == index
                        ? kInk
                        : Colors.black54,
                  ),
                  side: BorderSide(
                    color: _selectedPeriod == index
                        ? kOrange
                        : Colors.black12,
                  ),
                );
              }),
            ),

            const SizedBox(height: 14),

            // RINGKASAN PERIODE
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    icon: Icons.route_rounded,
                    label: 'JARAK',
                    value: '${filteredDistance.toStringAsFixed(2)} km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    icon: Icons.timer_outlined,
                    label: 'DURASI',
                    value: _formatDuration(filteredMinutes),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    icon: Icons.speed_rounded,
                    label: 'PACE RATA-RATA',
                    value: '$averagePace /km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    icon: Icons.fitness_center_rounded,
                    label: 'SESI',
                    value: '${filteredActivities.length}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // GRAFIK JARAK
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withValues(alpha: .06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .035),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grafik jarak aktivitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _selectedPeriod == 0
                        ? 'Performa 7 hari terakhir'
                        : _selectedPeriod == 1
                            ? 'Performa 30 hari terakhir'
                            : 'Seluruh aktivitas tersimpan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (filteredActivities.isEmpty)
                    const SizedBox(
                      height: 130,
                      child: Center(
                        child: Text(
                          'Belum ada aktivitas pada periode ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    _DistanceChart(
                      activities: filteredActivities,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // AKTIVITAS TERBARU
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Aktivitas terbaru',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
                Text(
                  '$count TOTAL',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF777D82),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (app.isLoadingActivities && activities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (app.activitiesError != null && activities.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 34,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aktivitas belum bisa dimuat dari server.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        app.activitiesError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _loadActivities,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else if (activities.isEmpty)
              const EmptyState(
                message:
                    'Belum ada aktivitas tersimpan. Yuk mulai bergerak!',
              )
            else
              ...activities.map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ActivityTile(activity: activity),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _darkStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: kOrange, size: 23),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: .06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kOrange, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: .7,
              fontWeight: FontWeight.w900,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: kInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _DistanceChart extends StatelessWidget {
  const _DistanceChart({
    required this.activities,
  });

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    final sorted = [...activities]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Maksimal 7 aktivitas agar grafik tetap rapi.
    final displayed = sorted.length > 7
        ? sorted.sublist(sorted.length - 7)
        : sorted;

    final maxDistance = displayed.fold<double>(
      0,
      (maximum, activity) =>
          math.max(maximum, activity.distanceKm),
    );

    final values = displayed
        .map((activity) => activity.distanceKm)
        .toList();

    final labels = displayed.map((activity) {
      final day = activity.date.day.toString().padLeft(2, '0');
      final month = activity.date.month.toString().padLeft(2, '0');
      return '$day/$month';
    }).toList();

    return SizedBox(
      height: 205,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maxDistance.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.black45,
                        ),
                      ),
                      Text(
                        (maxDistance / 2).toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.black45,
                        ),
                      ),
                      const Text(
                        '0.0',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _HomeLineChartPainter(
                      values: values,
                      maxValue: maxDistance,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 34),
              ...labels.map(
                (label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeLineChartPainter extends CustomPainter {
  _HomeLineChartPainter({
    required this.values,
    required this.maxValue,
  });

  final List<double> values;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const horizontalPadding = 8.0;
    const verticalPadding = 12.0;

    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - verticalPadding * 2;

    // Garis grid horizontal.
    final gridPaint = Paint()
      ..color = const Color(0xFFE9EAED)
      ..strokeWidth = 1;

    for (var i = 0; i < 3; i++) {
      final y = verticalPadding +
          chartHeight * i / 2;

      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : horizontalPadding +
              chartWidth * i / (values.length - 1);

      final ratio = maxValue > 0
          ? values[i] / maxValue
          : 0.0;

      final y = verticalPadding +
          chartHeight * (1 - ratio);

      points.add(Offset(x, y));
    }

    // Satu titik saja tetap terlihat di tengah grafik.
    if (points.length == 1) {
      final dotPaint = Paint()
        ..color = kOrange
        ..style = PaintingStyle.fill;

      canvas.drawCircle(points.first, 5, dotPaint);

      final ringPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(points.first, 5, ringPaint);
      return;
    }

    // Kurva halus mengikuti titik aktivitas.
    final linePath = Path()
      ..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final middleX = (current.dx + next.dx) / 2;

      linePath.cubicTo(
        middleX,
        current.dy,
        middleX,
        next.dy,
        next.dx,
        next.dy,
      );
    }

    // Area gradasi di bawah kurva.
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height - 1)
      ..lineTo(points.first.dx, size.height - 1)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x55FF7A18),
          Color(0x00FF7A18),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawPath(fillPath, fillPaint);

    // Garis utama berwarna oranye.
    final linePaint = Paint()
      ..color = kOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Titik aktivitas dengan lingkaran putih di tengah.
    for (final point in points) {
      canvas.drawCircle(
        point,
        5,
        Paint()..color = kOrange,
      );

      canvas.drawCircle(
        point,
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HomeLineChartPainter oldDelegate) {
    return oldDelegate.maxValue != maxValue ||
        oldDelegate.values != values;
  }
}
