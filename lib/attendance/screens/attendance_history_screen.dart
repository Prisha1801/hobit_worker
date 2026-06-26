import 'package:flutter/material.dart';

import '../../colors/appcolors.dart';
import '../../utils/app_bar.dart';
import '../models/attendance_record_model.dart';
import '../repository/attendance_repository.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<AttendanceRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AttendanceRepository.getMyAttendance();

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _records = result.data ?? [];
      } else {
        _error = result.message.isEmpty
            ? 'Failed to load attendance.'
            : result.message;
      }
    });
  }

  /// "2026-06-06T11:39:44.000000Z" -> "06:39 AM" (local).
  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
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

  /// "2026-06-05T18:30:00.000000Z" -> "05 Jun 2026" (local).
  String _formatDate(String iso) {
    if (iso.isEmpty) return '--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day.toString().padLeft(2, '0')} '
          '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: const CommonAppBar(
        title: 'My Attendance',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        color: kkblack,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _messageView(_error!, isError: true);
    }

    if (_records.isEmpty) {
      return _messageView('No attendance records yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCard(_records[i]),
    );
  }

  /// Scrollable so pull-to-refresh works even when empty.
  Widget _messageView(String msg, {bool isError = false}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isError ? Colors.red : Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AttendanceRecord r) {
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
          /// DATE + STATUS
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: kkblack),
              const SizedBox(width: 8),
              Text(
                _formatDate(r.date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (r.isActive ? kGreen : Colors.grey)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r.isActive ? 'Active' : 'Completed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: r.isActive ? kGreen : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          /// CHECK IN / CHECK OUT TIMES
          Row(
            children: [
              Expanded(
                child: _timeBlock(
                  Icons.login,
                  'Check In',
                  _formatTime(r.checkInAt),
                  kGreen,
                ),
              ),
              Container(width: 0.6, height: 36, color: const Color(0xFFC8CBD0)),
              Expanded(
                child: _timeBlock(
                  Icons.logout,
                  'Check Out',
                  _formatTime(r.checkOutAt),
                  Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// LOCATION
          Row(
            children: [
              const Icon(Icons.my_location, size: 15, color: Colors.black45),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${r.checkInLat}, ${r.checkInLon}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Distance: ${r.checkInDistanceM} m',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBlock(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
