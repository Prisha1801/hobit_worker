import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/booking_repo_home.dart';
import 'urls.dart';

/// Drives the "On My Way" live-tracking flow on the worker side.
///
/// Flow:
/// 1. POST /api/tracking/start  -> firebase_custom_token + driver_path
/// 2. Sign in to Firebase Auth with the custom token (hobitpartner project)
/// 3. Stream the device GPS straight to Firebase RTDB at `driver_path`
/// 4. End-service (or [stop]) cancels the stream and clears the node.
///
/// Single active trip at a time — starting a new one stops the previous.
class LiveTrackingService {
  LiveTrackingService._();
  static final LiveTrackingService instance = LiveTrackingService._();

  StreamSubscription<Position>? _positionSub;
  DatabaseReference? _driverRef;
  int? _activeBookingId;

  /// The booking currently being tracked, or null when idle.
  int? get activeBookingId => _activeBookingId;

  bool isTrackingBooking(int bookingId) => _activeBookingId == bookingId;

  /// RTDB for the hobitpartner project (URL not in google-services.json).
  FirebaseDatabase get _db =>
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: hobitRtdbUrl,
      );

  /// Starts tracking for [bookingId]. Returns a result map:
  /// { success: bool, message: String }.
  Future<Map<String, dynamic>> start(int bookingId) async {
    // Make sure location is usable before bothering the backend.
    final permOk = await _ensureLocationPermission();
    if (!permOk) {
      return {
        'success': false,
        'message': 'Location permission is required to share your location.',
      };
    }

    // 1. Ask the backend to open a tracking session.
    print('🟢 [Tracking] Calling /tracking/start for booking $bookingId ...');
    final res = await BookingApi.startTracking(bookingId);
    print('🟢 [Tracking] /tracking/start response => $res');

    if (res['success'] != true) {
      return {
        'success': false,
        'message': res['message']?.toString().isNotEmpty == true
            ? res['message'].toString()
            : 'Failed to start tracking.',
      };
    }

    final customToken = res['firebase_custom_token']?.toString() ?? '';
    final driverPath = res['driver_path']?.toString() ?? '';

    print('🟢 [Tracking] driver_path = "$driverPath"');
    print('🟢 [Tracking] custom_token length = ${customToken.length}');

    if (customToken.isEmpty || driverPath.isEmpty) {
      print('🔴 [Tracking] Missing custom_token or driver_path in response.');
      return {'success': false, 'message': 'Invalid tracking response.'};
    }

    // 2. Sign in to Firebase with the custom token (hobitpartner project).
    try {
      print('🟢 [Tracking] Signing in to Firebase with custom token ...');
      final cred =
          await FirebaseAuth.instance.signInWithCustomToken(customToken);
      print('🟢 [Tracking] Firebase sign-in OK. uid = ${cred.user?.uid}');
    } on FirebaseAuthException catch (e) {
      print('🔴 [Tracking] FirebaseAuthException '
          'code="${e.code}" message="${e.message}"');
      return {
        'success': false,
        'message': 'Could not connect to live tracking. (${e.code})',
      };
    } catch (e) {
      print('🔴 [Tracking] Firebase sign-in failed (generic): $e');
      return {
        'success': false,
        'message': 'Could not connect to live tracking.',
      };
    }

    // Stop any previous trip before starting the new one.
    await _stopStream();

    _activeBookingId = bookingId;
    _driverRef = _db.ref(driverPath);

    // Push an immediate fix so the customer sees the worker right away.
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _writePosition(pos);
    } catch (e) {
      debugPrint('Initial position write failed: $e');
    }

    // 3. Stream subsequent GPS updates to RTDB.
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      _writePosition,
      onError: (e) => debugPrint('Tracking position stream error: $e'),
    );

    return {
      'success': true,
      'message': res['message']?.toString().isNotEmpty == true
          ? res['message'].toString()
          : 'You are now sharing your location.',
    };
  }

  /// Stops tracking for [bookingId]. Cancels the GPS stream, clears the RTDB
  /// node and (best-effort) notifies the backend. Safe to call when idle.
  ///
  /// Pass [notifyBackend] = false after end-service, which already auto-stops
  /// the session server-side.
  Future<void> stop({int? bookingId, bool notifyBackend = true}) async {
    final id = bookingId ?? _activeBookingId;

    // Best-effort: remove the worker's live node so the customer stops seeing it.
    try {
      await _driverRef?.remove();
    } catch (e) {
      debugPrint('Failed to clear driver node: $e');
    }

    await _stopStream();

    if (notifyBackend && id != null) {
      await BookingApi.stopTracking(id);
    }

    _activeBookingId = null;
    _driverRef = null;
  }

  Future<void> _stopStream() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> _writePosition(Position pos) async {
    final ref = _driverRef;
    if (ref == null) return;
    try {
      // Keys MUST match the RTDB security rules schema for drivers/$worker_id:
      // required: lat, lng, ts ; allowed extra: heading, booking ; anything
      // else is rejected by the "$other": {".validate": false} rule.
      await ref.set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'heading': pos.heading,
        'ts': ServerValue.timestamp,
        if (_activeBookingId != null) 'booking': _activeBookingId,
      });
      print('🟢 [Tracking] GPS written -> lat:${pos.latitude}, '
          'lng:${pos.longitude}');
    } catch (e) {
      print('🔴 [Tracking] Failed to write GPS to RTDB: $e');
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }
}
