import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  String name = 'Atlet StraFit';
  String email = '';

  final List<Activity> activities = [];

  bool isLoadingActivities = false;
  String? activitiesError;

  double get totalDistance => activities.fold<double>(
        0,
        (sum, item) => sum + item.distanceKm,
      );

  int get totalMinutes => activities.fold<int>(
        0,
        (sum, item) => sum + item.durationMinutes,
      );

  /// Load the signed-in user's activities from the Laravel API.
  Future<void> loadActivities() async {
    isLoadingActivities = true;
    activitiesError = null;
    notifyListeners();

    try {
      final response = await ApiService.getActivities();
      final loaded = response
          .whereType<Map>()
          .map((item) => Activity.fromApi(Map<String, dynamic>.from(item)))
          .toList();

      activities
        ..clear()
        ..addAll(loaded);
    } catch (error) {
      activitiesError = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isLoadingActivities = false;
      notifyListeners();
    }
  }

  /// Keep this method for local UI changes; saved activities should use the API.
  void addActivity(Activity activity) {
    activities.insert(0, activity);
    notifyListeners();
  }

  void updateProfile(String newName, String newEmail) {
    name = newName;
    email = newEmail;
    notifyListeners();
  }
}