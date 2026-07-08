import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/emergency_alert_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import 'api_services.dart';
import 'urls.dart';

/// Worker-side Emergency / SOS alert APIs.
class EmergencyService {
  /// 🔥 Raise an SOS emergency alert.
  /// POST /api/worker/emergency-alert
  /// body: alert_type, message?, latitude?, longitude?
  ///
  /// The alert is no longer tied to a booking, so it can be raised regardless
  /// of any booking status.
  ///
  /// Returns: { success: bool, message: String, alert: EmergencyAlertModel? }.
  static Future<Map<String, dynamic>> raiseAlert({
    String alertType = 'safety',
    String? message,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final body = <String, dynamic>{
        'alert_type': alertType,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final res = await ApiService.postRequest(
        emergencyAlertUrl,
        body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = res.data;
      final alertJson = (data is Map)
          ? (data['data'] ?? data['alert'] ?? data['emergency_alert'])
          : null;

      final httpOk = res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300;

      return {
        'success': (data is Map && data['success'] == true) || httpOk,
        'message': (data is Map ? data['message']?.toString() : null) ??
            'SOS alert sent',
        'alert': alertJson is Map
            ? EmergencyAlertModel.fromJson(Map<String, dynamic>.from(alertJson))
            : null,
      };
    } catch (e) {
      debugPrint('Raise emergency alert error: $e');
      return {
        'success': false,
        'message': e is ApiException ? e.message : 'Failed to send SOS alert',
      };
    }
  }

  /// 🔥 The worker's own emergency alert history.
  /// GET /api/worker/emergency-alerts
  static Future<List<EmergencyAlertModel>> getMyAlerts() async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        emergencyAlertsUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = res.data;
      final list = (data is Map)
          ? (data['data'] ??
              data['alerts'] ??
              data['emergency_alerts'] ??
              const [])
          : (data is List ? data : const []);

      if (list is! List) return [];

      return list
          .whereType<Map>()
          .map((e) => EmergencyAlertModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Fetch emergency alerts error: $e');
      return [];
    }
  }
}
