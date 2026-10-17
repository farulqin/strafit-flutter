
import 'package:flutter/material.dart';

IconData getActivityIcon(String type) {
  switch (type.trim().toLowerCase()) {
    case 'jalan kaki':
    case 'walking':
      return Icons.directions_walk_rounded;

    case 'bersepeda':
    case 'cycling':
      return Icons.directions_bike_rounded;

    case 'lari':
    case 'running':
      return Icons.directions_run_rounded;

    default:
      return Icons.fitness_center_rounded;
  }
}
