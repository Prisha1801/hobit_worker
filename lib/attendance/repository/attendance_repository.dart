import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../api_services/api_services.dart';
import '../../api_services/urls.dart';
import '../../prefs/app_preference.dart';
import '../../prefs/preference_key.dart';
import '../models/attendance_record_model.dart';
import '../models/attendance_result.dart';
import '../models/check_in_model.dart';
import '../models/check_out_model.dart';

class AttendanceRepository {
  static Options _authOptions() {
    final token = AppPreference().getString(PreferencesKey.token);
    return Options(
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    );
  }

  /// Headers for multipart uploads — do NOT set Content-Type here so Dio can
  /// add the correct `multipart/form-data; boundary=..` itself.
  static Options _multipartOptions() {
    final token = AppPreference().getString(PreferencesKey.token);
    return Options(
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );
  }

  /// POST /api/checkin  (multipart)
  /// fields: lat, lon | file: photo (jpeg/jpg/png, max 2 MB — required)
  static Future<AttendanceResult<CheckInModel>> checkIn({
    required double lat,
    required double lon,
    required File photo,
  }) async {
    try {
      final formData = FormData.fromMap({
        "lat": lat.toString(),
        "lon": lon.toString(),
        "photo": await MultipartFile.fromFile(
          photo.path,
          filename: photo.path.split(Platform.pathSeparator).last,
        ),
      });

      final res = await ApiService.postRequest(
        checkInUrl,
        formData,
        options: _multipartOptions(),
      );

      final body = res.data;
      return AttendanceResult<CheckInModel>(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
        data: body['data'] != null
            ? CheckInModel.fromJson(Map<String, dynamic>.from(body['data']))
            : null,
      );
    } on ApiException catch (e) {
      return AttendanceResult<CheckInModel>(success: false, message: e.message);
    } catch (e) {
      debugPrint("Check-in error: $e");
      return AttendanceResult<CheckInModel>(
        success: false,
        message: 'Something went wrong while checking in.',
      );
    }
  }

  /// GET /api/attendance/my — paginated attendance history.
  /// The list lives at `data.data`; pagination meta is ignored for now.
  static Future<AttendanceResult<List<AttendanceRecord>>> getMyAttendance({
    int page = 1,
  }) async {
    try {
      final res = await ApiService.getRequest(
        myAttendanceUrl,
        queryParameters: {"page": page},
        options: _authOptions(),
      );

      final body = res.data;
      final list = (body['data']?['data'] as List?) ?? const [];

      return AttendanceResult<List<AttendanceRecord>>(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
        data: list
            .map((e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } on ApiException catch (e) {
      return AttendanceResult<List<AttendanceRecord>>(
        success: false,
        message: e.message,
      );
    } catch (e) {
      debugPrint("My-attendance error: $e");
      return AttendanceResult<List<AttendanceRecord>>(
        success: false,
        message: 'Something went wrong while loading attendance.',
      );
    }
  }

  /// POST /api/checkout  body: { "lat": .., "lon": .. }
  static Future<AttendanceResult<CheckOutModel>> checkOut({
    required double lat,
    required double lon,
  }) async {
    try {
      final res = await ApiService.postRequest(
        checkOutUrl,
        {"lat": lat, "lon": lon},
        options: _authOptions(),
      );

      final body = res.data;
      return AttendanceResult<CheckOutModel>(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
        data: body['data'] != null
            ? CheckOutModel.fromJson(Map<String, dynamic>.from(body['data']))
            : null,
      );
    } on ApiException catch (e) {
      return AttendanceResult<CheckOutModel>(success: false, message: e.message);
    } catch (e) {
      debugPrint("Check-out error: $e");
      return AttendanceResult<CheckOutModel>(
        success: false,
        message: 'Something went wrong while checking out.',
      );
    }
  }
}
