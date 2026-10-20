import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app/app_theme.dart';
import '../models/activity.dart';
import '../services/api_service.dart';
import '../widgets/stat_card.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key, required this.activity});

  final Activity activity;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  List<LatLng> _route = [];
  bool _loadingRoute = true;
  String? _routeError;

  Activity get activity => widget.activity;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final id = activity.id;

    if (id == null) {
      setState(() => _loadingRoute = false);
      return;
    }

    setState(() {
      _loadingRoute = true;
      _routeError = null;
    });

    try {
      final data = await ApiService.getActivityRoute(id);

      final points = data.whereType<Map>().toList()
        ..sort((a, b) {
          final x = int.tryParse('${a['sequence']}') ?? 0;
          final y = int.tryParse('${b['sequence']}') ?? 0;
          return x.compareTo(y);
        });

      final route = <LatLng>[];
      for (final p in points) {
        final lat = double.tryParse('${p['latitude']}');
        final lng = double.tryParse('${p['longitude']}');
        if (lat != null && lng != null) route.add(LatLng(lat, lng));
      }

      if (!mounted) return;
      setState(() {
        _route = route;
        _loadingRoute = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _routeError = error.toString().replaceFirst('Exception: ', '');
        _loadingRoute = false;
      });
    }
  }

  String get _durationText {
    final s = activity.durationSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  String get _paceText {
    if (activity.distanceKm <= 0 || activity.durationSeconds <= 0) {
      return '--:--';
    }
    final pace = (activity.durationSeconds / activity.distanceKm).round();
    return '${pace ~/ 60}:${(pace % 60).toString().padLeft(2, '0')}';
  }

  String get _speedText {
    if (activity.distanceKm <= 0 || activity.durationSeconds <= 0) {
      return '--';
    }
    final kmh = activity.distanceKm / (activity.durationSeconds / 3600);
    return kmh.toStringAsFixed(1);
  }

  Widget _buildMap() {
    if (_loadingRoute) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_routeError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _routeError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loadRoute,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_route.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Rute GPS tidak tersimpan untuk aktivitas ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    final hasLine = _route.length >= 2;

    return FlutterMap(
      options: MapOptions(
        initialCenter: _route.first,
        initialZoom: 16,
        initialCameraFit: hasLine
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(_route),
                padding: const EdgeInsets.all(36),
                maxZoom: 18,
              )
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.strafit.app',
        ),
        if (hasLine)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route,
                strokeWidth: 5,
                color: kOrange,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: _route.first,
              width: 28,
              height: 28,
              child: const Icon(Icons.trip_origin_rounded,
                  color: Colors.green, size: 26),
            ),
            if (hasLine)
              Marker(
                point: _route.last,
                width: 28,
                height: 28,
                child: const Icon(Icons.flag_rounded,
                    color: Colors.red, size: 26),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (activity.type) {
      'Bersepeda' => Icons.directions_bike_rounded,
      'Jalan kaki' => Icons.directions_walk_rounded,
      _ => Icons.directions_run_rounded,
    };

    final d = activity.date;
    final dateText =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Aktivitas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // PETA RUTE
          Container(
            height: 280,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: _buildMap(),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kOrange, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${activity.type} • $dateText',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.route_rounded,
                  label: 'Jarak',
                  value: '${activity.distanceKm.toStringAsFixed(2)} km',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Durasi',
                  value: _durationText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.speed_rounded,
                  label: 'Pace rata-rata',
                  value: '$_paceText /km',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.bolt_rounded,
                  label: 'Kecepatan',
                  value: '$_speedText km/j',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
