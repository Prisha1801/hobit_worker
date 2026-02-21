import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../api_services/api_services.dart';
import '../models/booking_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';

class BookingApi {
  static Future<List<AssignedBookingModel>> getAssignedBookings() async {
    final token = AppPreference().getString(PreferencesKey.token);

    final res = await ApiService.getRequest(
      "/api/worker/bookings",
      queryParameters: {"status": "assigned"},
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ),
    );

    final List data = res.data['data'];

    return data
        .map((e) => AssignedBookingModel.fromJson(e))
        .toList();
  }

  static Future<List<AssignedBookingModel>> getInProgressBookings() async {
    final token = AppPreference().getString(PreferencesKey.token);

    final res = await ApiService.getRequest(
      "/api/worker/bookings",
      queryParameters: {"status": "inprogress"},
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ),
    );

    final List data = res.data['data'];
    return data.map((e) => AssignedBookingModel.fromJson(e)).toList();
  }

  static Future<bool> sendStartOtp(int bookingId) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.postRequest(
        "/api/booking/send-start-otp",
        {
          "booking_id": bookingId,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Send Start OTP Error: $e");
      return false;
    }
  }

  static Future<bool> verifyStartOtp({
    required int bookingId,
    required String otp,
  }) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.postRequest(
        "/api/booking/verifyotp/$bookingId/start",
        {
          "otp": otp,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Verify OTP Error: $e");
      return false;
    }
  }
}
