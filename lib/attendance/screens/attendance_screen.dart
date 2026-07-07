import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api_services/location_service.dart';
import '../../colors/appcolors.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_bar.dart';
import '../models/check_in_model.dart';
import '../models/check_out_model.dart';
import '../repository/attendance_repository.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isCheckedIn = false;

  /// Which action is currently running: 'in', 'out', or null when idle.
  String? _busyAction;
  bool get _loading => _busyAction != null;

  CheckInModel? _lastCheckIn;
  CheckOutModel? _lastCheckOut;

  /// Format an ISO/UTC string like "2026-06-06T11:12:00.000000Z"
  /// into a readable local time "hh:mm a".
  String _formatTime(String iso) {
    if (iso.isEmpty) return '--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${h.toString().padLeft(2, '0')}:$m $period';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _handleCheckIn() async {
    if (_loading) return;

    // 1) Capture the attendance photo (required by backend).
    //    imageQuality + maxWidth keep the file comfortably under the 2 MB limit.
    final XFile? shot = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
      maxWidth: 1080,
    );

    if (!mounted) return;
    if (shot == null) {
      // Worker cancelled the camera — photo is mandatory, so abort.
      _showSnack(AppLocalizations.of(context)!.attPhotoRequired, false);
      return;
    }

    setState(() => _busyAction = 'in');

    try {
      final position = await LocationService.getCurrentLocation();

      final result = await AttendanceRepository.checkIn(
        lat: position.latitude,
        lon: position.longitude,
        photo: File(shot.path),
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _isCheckedIn = true;
          _lastCheckIn = result.data;
          _lastCheckOut = null;
        });
      } else if (_looksAlreadyCheckedIn(result.message)) {
        // Server says worker is already checked in today —
        // sync the UI so the Check Out button becomes available.
        setState(() => _isCheckedIn = true);
      }
      final loc = AppLocalizations.of(context)!;
      _showSnack(
        result.message.isEmpty
            ? (result.success ? loc.attCheckInSuccess : loc.attCheckInFailed)
            : result.message,
        result.success || _looksAlreadyCheckedIn(result.message),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.attLocationError, false);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _handleCheckOut() async {
    if (_loading) return;
    setState(() => _busyAction = 'out');

    try {
      final position = await LocationService.getCurrentLocation();

      final result = await AttendanceRepository.checkOut(
        lat: position.latitude,
        lon: position.longitude,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _isCheckedIn = false;
          _lastCheckOut = result.data;
        });
      }
      final loc = AppLocalizations.of(context)!;
      _showSnack(
        result.message.isEmpty
            ? (result.success ? loc.attCheckOutSuccess : loc.attCheckOutFailed)
            : result.message,
        result.success,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.attLocationError, false);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  /// Detects a server message that means the worker is already checked in.
  bool _looksAlreadyCheckedIn(String msg) {
    final m = msg.toLowerCase();
    return m.contains('already') && m.contains('check');
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? kGreen : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: kWhite,
      appBar: CommonAppBar(title: loc.attendance),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 28),

            /// CHECK IN BUTTON
            _buildActionButton(
              label: loc.attCheckIn,
              icon: Icons.login,
              color: kGreen,
              enabled: !_isCheckedIn && !_loading,
              busy: _busyAction == 'in',
              onTap: _handleCheckIn,
            ),
            const SizedBox(height: 14),

            /// CHECK OUT BUTTON
            _buildActionButton(
              label: loc.attCheckOut,
              icon: Icons.logout,
              color: Colors.redAccent,
              enabled: _isCheckedIn && !_loading,
              busy: _busyAction == 'out',
              onTap: _handleCheckOut,
            ),

            const SizedBox(height: 28),

            if (_lastCheckIn != null || _lastCheckOut != null) _buildDetailsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final loc = AppLocalizations.of(context)!;
    final bool active = _isCheckedIn;
    final Color accent = active ? kGreen : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2),
            ),
            child: Icon(
              active ? Icons.check_circle : Icons.fingerprint,
              size: 44,
              color: accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            active ? loc.attCheckedInStatus : loc.attCheckedOutStatus,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: active ? kGreen : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          if (active && _lastCheckIn != null)
            Text(
              loc.attSince(_formatTime(_lastCheckIn!.loggedAt)),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            )
          else
            Text(
              loc.attMarkPrompt,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required bool busy,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          elevation: enabled ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8CBD0), width: 0.6),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.attLastActivity,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          if (_lastCheckOut != null) ...[
            _detailRow(Icons.login, loc.attCheckInTime,
                _formatTime(_lastCheckOut!.checkInAt)),
            const Divider(height: 18),
            _detailRow(Icons.logout, loc.attCheckOutTime,
                _formatTime(_lastCheckOut!.checkOutAt)),
            const Divider(height: 18),
            _detailRow(Icons.social_distance, loc.attDistance,
                '${_lastCheckOut!.checkOutDistanceM} m'),
          ] else if (_lastCheckIn != null) ...[
            _detailRow(Icons.login, loc.attCheckInTime,
                _formatTime(_lastCheckIn!.loggedAt)),
            const Divider(height: 18),
            _detailRow(Icons.my_location, loc.attLocationLabel,
                '${_lastCheckIn!.latitude}, ${_lastCheckIn!.longitude}'),
            const Divider(height: 18),
            _detailRow(Icons.social_distance, loc.attDistance,
                '${_lastCheckIn!.distanceM} m'),
            if (_lastCheckIn!.photoUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _lastCheckIn!.photoUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : const SizedBox(
                              height: 150,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kGreen),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
