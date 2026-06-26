import 'dart:async';
import 'package:flutter/material.dart';
import 'booking_repo_home.dart';

/// Live ticking timer for an in-progress booking.
///
/// Strategy: fetch the server's `elapsed_seconds` once as a baseline, remember
/// the local time at which we captured it, then recompute elapsed locally every
/// second (baseline + time-since-capture). We re-sync with the server every 30s
/// so the counter never drifts away from the backend value.
class ServiceTimerWidget extends StatefulWidget {
  final int bookingId;

  const ServiceTimerWidget({Key? key, required this.bookingId})
      : super(key: key);

  @override
  State<ServiceTimerWidget> createState() => _ServiceTimerWidgetState();
}

class _ServiceTimerWidgetState extends State<ServiceTimerWidget> {
  Timer? _ticker; // refreshes the display every second
  Timer? _resync; // pulls a fresh baseline from the server periodically

  bool _loading = true;
  bool _running = false;
  int _baseElapsed = 0; // seconds reported by the server
  DateTime? _baseAt; // local time when the baseline was captured

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _running) setState(() {});
    });
    _resync = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  Future<void> _load() async {
    final data = await BookingApi.getBookingTimer(widget.bookingId);
    if (!mounted) return;

    if (data == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _baseElapsed = data.elapsedSeconds;
      _baseAt = DateTime.now();
      _running = data.running;
      _loading = false;
    });
  }

  int get _currentElapsed {
    if (!_running || _baseAt == null) return _baseElapsed;
    final extra = DateTime.now().difference(_baseAt!).inSeconds;
    return _baseElapsed + (extra > 0 ? extra : 0);
  }

  String _format(int totalSeconds) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return "${two(h)}:${two(m)}:${two(s)}";
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _resync?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _running ? Icons.timer : Icons.timer_off,
            size: 15,
            color: Colors.blue,
          ),
          const SizedBox(width: 5),
          Text(
            _format(_currentElapsed),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
