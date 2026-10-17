import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../models/activity.dart';
import '../widgets/stat_card.dart';

class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final isRun = activity.type == 'Lari';
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Aktivitas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kOrange.withValues(alpha: 0.18), kOrange.withValues(alpha: 0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              isRun ? Icons.directions_run_rounded : Icons.directions_bike_rounded,
              size: 82,
              color: kOrange,
            ),
          ),
          const SizedBox(height: 22),
          Text(activity.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            '${activity.type} • ${activity.date.day}/${activity.date.month}/${activity.date.year}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.route_rounded,
                  label: 'Jarak',
                  value: '${activity.distanceKm.toStringAsFixed(1)} km',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Durasi',
                  value: '${activity.durationMinutes} mnt',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Detail rute GPS dan pace otomatis belum tersedia pada versi awal ini.',
                style: TextStyle(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
