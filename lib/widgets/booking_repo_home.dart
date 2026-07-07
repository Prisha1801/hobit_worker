import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../api_services/api_services.dart';
import '../api_services/urls.dart';
import '../models/booking_model.dart';
import '../models/booking_timer_model.dart';
import '../models/extend_service_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';

class BookingApi {

  // NOTE: Accept / Decline API integration disabled as per backend developer's
  // request (accept/decline API not to be integrated).
  // /// POST /api/worker/bookingrequest/{id}/accept
  // static Future<Map<String, dynamic>> acceptBooking(int bookingId) async {
  //   try {
  //     final token = AppPreference().getString(PreferencesKey.token);
  //
  //     final res = await ApiService.postRequest(
  //       '/api/worker/bookingrequest/$bookingId/accept',
  //       {},
  //       options: Options(
  //         headers: {
  //           'Authorization': 'Bearer $token',
  //           'Accept': 'application/json',
  //           'Content-Type': 'application/json',
  //         },
  //       ),
  //     );
  //
  //     return {
  //       'success': res.data['success'] == true,
  //       'message': res.data['message']?.toString() ?? '',
  //       'acceptance_status': res.data['acceptance_status']?.toString() ?? '',
  //     };
  //   } catch (e) {
  //     debugPrint("Accept booking error: $e");
  //     return {'success': false, 'message': 'Something went wrong'};
  //   }
  // }
  //
  // /// POST /api/worker/bookingrequest/{id}/decline   body(optional): { "reason": ".." }
  // static Future<Map<String, dynamic>> declineBooking(
  //   int bookingId, {
  //   String? reason,
  // }) async {
  //   try {
  //     final token = AppPreference().getString(PreferencesKey.token);
  //
  //     final res = await ApiService.postRequest(
  //       '/api/worker/bookingrequest/$bookingId/decline',
  //       (reason != null && reason.trim().isNotEmpty)
  //           ? {'reason': reason.trim()}
  //           : {},
  //       options: Options(
  //         headers: {
  //           'Authorization': 'Bearer $token',
  //           'Accept': 'application/json',
  //           'Content-Type': 'application/json',
  //         },
  //       ),
  //     );
  //
  //     return {
  //       'success': res.data['success'] == true,
  //       'message': res.data['message']?.toString() ?? '',
  //       'acceptance_status': res.data['acceptance_status']?.toString() ?? '',
  //     };
  //   } catch (e) {
  //     debugPrint("Decline booking error: $e");
  //     return {'success': false, 'message': 'Something went wrong'};
  //   }
  // }

  /// 🔥 LIVE TRACKING — worker taps "On My Way".
  /// POST /api/tracking/start  body: { "booking_id": id }
  /// Returns the Firebase custom token + driver_path the worker app writes GPS to.
  static Future<Map<String, dynamic>> startTracking(int bookingId) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.postRequest(
        trackingStartUrl,
        {"booking_id": bookingId},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      return {
        "success": res.data["success"] == true,
        "message": res.data["message"]?.toString() ?? "",
        "worker_id": res.data["worker_id"],
        "firebase_custom_token":
            res.data["firebase_custom_token"]?.toString() ?? "",
        "driver_path": res.data["driver_path"]?.toString() ?? "",
      };
    } catch (e) {
      debugPrint("Start tracking error: $e");
      return {"success": false, "message": "Failed to start tracking"};
    }
  }

  /// 🔥 LIVE TRACKING — optional standalone stop.
  /// POST /api/tracking/stop  body: { "booking_id": id }
  /// (end-service already auto-stops tracking on the backend.)
  static Future<Map<String, dynamic>> stopTracking(int bookingId) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.postRequest(
        trackingStopUrl,
        {"booking_id": bookingId},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      return {
        "success": res.data["success"] == true,
        "message": res.data["message"]?.toString() ?? "",
      };
    } catch (e) {
      debugPrint("Stop tracking error: $e");
      return {"success": false, "message": "Failed to stop tracking"};
    }
  }

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

  // ❌ OLD FLOW — SMS / WhatsApp OTP send-resend (kept for reference, do not remove)
  // static Future<bool> sendStartOtp(int bookingId, {String type = "sms"}) async {  ///resend otp
  //   try {
  //     final token = AppPreference().getString(PreferencesKey.token);
  //
  //     final res = await ApiService.postRequest(
  //       "/api/booking/send-start-otp",
  //       {
  //         "booking_id": bookingId,
  //         "type": type,
  //       },
  //       options: Options(
  //         headers: {
  //           "Authorization": "Bearer $token",
  //           "Accept": "application/json",
  //           "Content-Type": "application/json",
  //         },
  //       ),
  //     );
  //
  //     return res.statusCode == 200;
  //   } catch (e) {
  //     debugPrint("Send Start OTP Error: $e");
  //     return false;
  //   }
  // }

  /// 🔥 NEW FLOW — generate the customer start code.
  /// POST /api/booking/generate-codes   body: { "booking_id": id }
  static Future<Map<String, dynamic>> generateStartCode(int bookingId) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.postRequest(
        "/api/booking/generate-codes",
        {"booking_id": bookingId},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      return {
        "success": res.data["success"] == true,
        "message": res.data["message"]?.toString() ?? "",
        "code": res.data["customer_start_code"]?.toString() ?? "",
        "expires_at": res.data["start_expires_at"]?.toString() ?? "",
      };
    } catch (e) {
      debugPrint("Generate start code error: $e");
      return {"success": false, "message": "Failed to generate code"};
    }
  }

  /// 🔥 NEW FLOW — verify the customer start code.
  /// POST /api/booking/verifycode/{id}/start   body: { "otp": code }
  static Future<Map<String, dynamic>> verifyStartCode({
    required int bookingId,
    required String otp,
  }) async {
    try {
      final res = await ApiService.postRequest(
        "/api/booking/verifycode/$bookingId/start",
        {"otp": otp},
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      return {
        "success": res.data["success"] == true,
        "message": res.data["message"]?.toString() ?? "Something went wrong",
        "status": res.data["status"]?.toString() ?? "",
      };
    } catch (e) {
      return {"success": false, "message": "Server error"};
    }
  }

  /// 🔥 NEW FLOW — end an in-progress service.
  /// POST /api/booking/end-service   body: { "booking_id": id }
  static Future<Map<String, dynamic>> endService(int bookingId) async {
    try {
      final res = await ApiService.postRequest(
        "/api/booking/end-service",
        {"booking_id": bookingId},
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      return {
        "success": res.data["success"] == true,
        "message": res.data["message"]?.toString() ?? "",
        "status": res.data["status"]?.toString() ?? "",
      };
    } catch (e) {
      debugPrint("End service error: $e");
      return {"success": false, "message": "Failed to end service"};
    }
  }

  /// 🔥 Live service timer for an in-progress booking.
  /// GET /api/booking/timer?booking_id={id}
  static Future<BookingTimerModel?> getBookingTimer(int bookingId) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        "/api/booking/timer",
        queryParameters: {"booking_id": bookingId},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

      if (res.data["success"] != true) return null;

      return BookingTimerModel.fromJson(res.data);
    } catch (e) {
      debugPrint("Booking timer error: $e");
      return null;
    }
  }


  static Future<Map<String, dynamic>> verifyStartOtp({
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

      return {
        "success": res.data["success"] == true,
        "message": res.data["message"] ?? "Something went wrong"
      };

    } catch (e) {
      return {
        "success": false,
        "message": "Server error"
      };
    }
  }


  /// 🔥 Share the worker's current location with the customer(s).
  /// Called right after the worker taps "Confirm Location" post-login, so the
  /// customer starts seeing the worker's location from that moment (not only
  /// when the worker opens the map).
  static Future<void> broadcastWorkerLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print("📍 [ConfirmLocation] Worker location: $latitude, $longitude");

      final assigned = await getAssignedBookings();
      final inProgress = await getInProgressBookings();

      // Only notify bookings the worker is actually serving:
      // accepted-assigned + in-progress.
      final bookings = [
        ...assigned.where((b) => b.acceptanceStatus == 'accepted'),
        ...inProgress,
      ];

      print(
        "📍 [ConfirmLocation] Active bookings to notify: "
        "${bookings.map((b) => 'BK-${b.id}').toList()}",
      );

      if (bookings.isEmpty) {
        print("📍 [ConfirmLocation] No active bookings — location not sent.");
        return;
      }

      for (final b in bookings) {
        final ok = await sendWorkerLiveLocation(
          bookingId: b.id,
          latitude: latitude,
          longitude: longitude,
        );
        print("📍 [ConfirmLocation] Sent to BK-${b.id} → success=$ok");
      }
    } catch (e) {
      print("📍 [ConfirmLocation] Error broadcasting worker location: $e");
    }
  }

  static Future<bool> sendWorkerLiveLocation({
    required int bookingId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final response = await ApiService.postRequest(
        "/api/worker/location",
        {
          "booking_id": bookingId,
          "latitude": latitude,
          "longitude": longitude,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Live location error: $e");
      return false;
    }
  }


  static Future<List<BookingExtensionModel>> getBookingExtensions(int bookingId) async {
    final token = AppPreference().getString(PreferencesKey.token);

    final res = await ApiService.getRequest(
      "/api/instant-bookings/$bookingId/extensions",
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ),
    );

    final List list = res.data["booking"]["extensions"];

    return list
        .map((e) => BookingExtensionModel.fromJson(e))
        .toList();
  }

  static Future<bool> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.patchRequest(
        "/api/bookings/$bookingId/status",
        {
          "status": status,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

      return res.data["success"] == true;

    } catch (e) {
      debugPrint("Status update error: $e");
      return false;
    }
  }

  /// Edit booking details (date, time slot, address, amount) — coordinator use.
  static Future<bool> editBooking({
    required int bookingId,
    String? bookingDate,
    String? timeSlot,
    String? address,
    String? amount,
  }) async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final Map<String, dynamic> body = {};
      if (bookingDate != null) body['booking_date'] = bookingDate;
      if (timeSlot != null)    body['time_slot']    = timeSlot;
      if (address != null)     body['address']      = address;
      if (amount != null)      body['amount']       = amount;

      final res = await ApiService.putRequest(
        "/api/coordinator/bookings/$bookingId",
        body,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      return res.data["success"] == true;
    } catch (e) {
      debugPrint("Edit booking error: $e");
      return false;
    }
  }

}
