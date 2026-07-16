import 'dart:async';

import 'package:flutter/material.dart';

import '../api_services/emergency_service.dart';
import '../api_services/location_service.dart';
import '../l10n/app_localizations.dart';
import '../models/emergency_alert_model.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';

/// Selectable emergency alert types accepted by the backend
/// (safety|medical|accident|harassment|other).
const List<Map<String, dynamic>> _sosAlertTypes = [
  {'value': 'safety', 'label': 'Safety', 'icon': Icons.shield_outlined},
  {'value': 'medical', 'label': 'Medical', 'icon': Icons.medical_services_outlined},
  {'value': 'accident', 'label': 'Accident', 'icon': Icons.car_crash_outlined},
  {'value': 'harassment', 'label': 'Harassment', 'icon': Icons.report_gmailerrorred_outlined},
  {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
];

/// Snapshot of an active SOS alert, kept by the screen that raised it so the
/// active screen can be re-opened until it is cancelled.
class SosSession {
  final String raisedByName;
  final DateTime sentAt;
  final String location;
  final int? bookingId;
  final EmergencyAlertModel? alert;
  final String? alertType;
  final String? serverMessage;

  SosSession({
    required this.raisedByName,
    required this.sentAt,
    required this.location,
    this.bookingId,
    this.alert,
    this.alertType,
    this.serverMessage,
  });
}

/// Adds SOS alert raising to any [State] (worker or coordinator screens).
///
/// Usage: `class _MyScreenState extends State<MyScreen> with SosMixin<MyScreen> { ... }`
/// then wire `AppBarHome(onEmergencyPressed: () => showSosDialog())`.
mixin SosMixin<T extends StatefulWidget> on State<T> {
  /// The currently active (uncancelled) SOS session, if any. While this is
  /// non-null, tapping the emergency button re-opens the active SOS screen
  /// instead of showing the alert dialog again. Cleared only when the
  /// alert is cancelled.
  SosSession? _activeSosSession;

  Future<void> _openSosScreen(SosSession session) async {
    final cancelled = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SosActiveScreen(
          raisedByName: session.raisedByName,
          sentAt: session.sentAt,
          location: session.location,
          bookingId: session.bookingId,
          alert: session.alert,
          alertType: session.alertType,
          serverMessage: session.serverMessage,
        ),
      ),
    );
    if (cancelled == true && mounted) {
      setState(() => _activeSosSession = null);
    }
  }

  /// Opens the SOS confirmation dialog (or re-opens the active alert screen
  /// if one is already in flight). [activeBookingId], when provided, is
  /// attached to the alert for context.
  void showSosDialog({int? activeBookingId}) {
    final loc = AppLocalizations.of(context)!;

    // An alert is already active and not yet cancelled — re-open it instead of
    // raising a new one.
    if (_activeSosSession != null) {
      _openSosScreen(_activeSosSession!);
      return;
    }

    final messageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool sending = false;
        String alertType = 'safety';
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                Text(
                  loc.sosAlert,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.sosDescription,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  if (activeBookingId != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      loc.sosBooking(activeBookingId),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    loc.sosTypeOfEmergency,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sosAlertTypes.map((t) {
                      final selected = alertType == t['value'];
                      return ChoiceChip(
                        selected: selected,
                        onSelected: sending
                            ? null
                            : (_) => setDialogState(
                                () => alertType = t['value'] as String),
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: Colors.red.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected ? Colors.red : Colors.grey.shade300,
                          ),
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              t['icon'] as IconData,
                              size: 15,
                              color: selected ? Colors.red : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              emergencyTypeLabel(loc, t['value'] as String),
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? Colors.red : Colors.black87,
                                fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: messageController,
                    enabled: !sending,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: loc.sosAddMessage,
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: Text(loc.no,
                    style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                  setDialogState(() => sending = true);

                  final dialogNav = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  final raisedByName =
                  AppPreference().getString(PreferencesKey.name);
                  final sentAt = DateTime.now();

                  // Best-effort live location (fields are optional on the API).
                  double? lat;
                  double? lng;
                  try {
                    final pos = await LocationService.getCurrentLocation();
                    lat = pos.latitude;
                    lng = pos.longitude;
                    LocationStore.lat = lat;
                    LocationStore.lng = lng;
                  } catch (e) {
                    debugPrint('SOS location fetch failed: $e');
                    if (LocationStore.lat != 0.0 ||
                        LocationStore.lng != 0.0) {
                      lat = LocationStore.lat;
                      lng = LocationStore.lng;
                    }
                  }

                  final result = await EmergencyService.raiseAlert(
                    alertType: alertType,
                    message: messageController.text,
                    latitude: lat,
                    longitude: lng,
                  );

                  if (!mounted) return;

                  final success = result['success'] == true;
                  final msg = result['message']?.toString() ?? '';

                  if (!success) {
                    setDialogState(() => sending = false);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(msg.isEmpty
                            ? loc.sosFailed
                            : msg),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  dialogNav.pop();

                  // Remember this alert so re-tapping emergency re-opens
                  // the active screen until it is cancelled.
                  final session = SosSession(
                    raisedByName: raisedByName,
                    sentAt: sentAt,
                    location: LocationStore.address,
                    bookingId: activeBookingId,
                    alert: result['alert'] as EmergencyAlertModel?,
                    alertType: alertType,
                    serverMessage: msg,
                  );
                  setState(() => _activeSosSession = session);
                  _openSosScreen(session);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: sending
                    ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : Text(loc.sosYesSend,
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SOS Active Screen
// ─────────────────────────────────────────────

/// Maps a backend emergency-type value (safety|medical|accident|harassment|other)
/// to its localized label.
String emergencyTypeLabel(AppLocalizations loc, String value) {
  switch (value) {
    case 'medical':
      return loc.sosTypeMedical;
    case 'accident':
      return loc.sosTypeAccident;
    case 'harassment':
      return loc.sosTypeHarassment;
    case 'other':
      return loc.sosTypeOther;
    case 'safety':
      return loc.sosTypeSafety;
    default:
      return loc.sosTypeOther;
  }
}

class SosActiveScreen extends StatefulWidget {
  final String raisedByName;
  final DateTime sentAt;
  final String location;
  final int? bookingId;

  /// The alert returned by the backend (null if the response carried no body).
  final EmergencyAlertModel? alert;

  /// The alert type that was selected (fallback when [alert] is null).
  final String? alertType;

  /// Confirmation message returned by the server.
  final String? serverMessage;

  const SosActiveScreen({
    super.key,
    required this.raisedByName,
    required this.sentAt,
    required this.location,
    this.bookingId,
    this.alert,
    this.alertType,
    this.serverMessage,
  });

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_SosUpdate> _updates = [];
  Timer? _updateTimer;
  int _updateIndex = 0;

  late final List<String> _staticUpdates;

  /// alert type shown in the header / info tile.
  String get _alertType =>
      widget.alert?.alertType ?? widget.alertType ?? 'safety';

  /// current status reported by the backend.
  String get _status => widget.alert?.status ?? 'pending';

  /// Guards one-time, localization-dependent setup in [didChangeDependencies].
  bool _didInitLocalized = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Localizations are only available once dependencies are ready, so this
    // one-time setup lives here rather than in initState().
    if (_didInitLocalized) return;
    _didInitLocalized = true;

    final loc = AppLocalizations.of(context)!;
    _staticUpdates = [
      loc.sosLocatingResponder,
      loc.sosResponderAssigned,
    ];

    // Seed the timeline with the real server confirmation.
    final confirm = (widget.serverMessage?.trim().isNotEmpty == true)
        ? widget.serverMessage!.trim()
        : loc.sosAlertReceived;
    _updates.add(_SosUpdate(message: confirm, time: widget.sentAt));

    _updateTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (_updateIndex < _staticUpdates.length) {
        setState(() {
          _updates.add(_SosUpdate(
            message: _staticUpdates[_updateIndex],
            time: DateTime.now(),
          ));
          _updateIndex++;
        });
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _prettyStatus(AppLocalizations loc, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return loc.pending;
      case 'assigned':
        return loc.assigned;
      case 'completed':
        return loc.completed;
      case '':
        return loc.pending;
      default:
        return '${status[0].toUpperCase()}${status.substring(1)}';
    }
  }

  void _cancelSos() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(loc.sosCancelTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(loc.sosCancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.no, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Signal the caller that the alert was cancelled so it clears
              // the active session (a plain back gesture returns null and
              // keeps the session alive).
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.sosCancelled),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(loc.sosYesCancel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.sos, color: Colors.white, size: 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.sosAlertSent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.sosSentAt(_formatTime(widget.sentAt)),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.person,
                    label: loc.sosWorker,
                    value: widget.raisedByName.isEmpty ? loc.sosUnknown : widget.raisedByName,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.crisis_alert,
                    label: loc.sosEmergencyType,
                    value: '${emergencyTypeLabel(loc, _alertType)}  •  ${_prettyStatus(loc, _status)}'
                        '${widget.alert?.id != null ? '  (#${widget.alert!.id})' : ''}',
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.location_on,
                    label: loc.sosLastKnownLocation,
                    value: widget.location.isEmpty ? loc.sosLocationUnavailable : widget.location,
                  ),
                  if (widget.bookingId != null) ...[
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: Icons.work_outline,
                      label: loc.sosActiveBooking,
                      value: 'BK-${widget.bookingId}',
                    ),
                  ],
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.support_agent,
                    label: loc.sosSupportContact,
                    value: '+91 98765 43210',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Live status updates
            if (_updates.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.sosStatusUpdates,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _updates.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final u = _updates[i];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.circle, size: 8, color: Colors.red),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(u.message,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                                const SizedBox(width: 8),
                                Text(_formatTime(u.time),
                                    style: const TextStyle(fontSize: 11, color: Colors.black45)),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Spacer(),

            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _cancelSos,
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: Text(
                    loc.sosCancel,
                    style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosUpdate {
  final String message;
  final DateTime time;
  _SosUpdate({required this.message, required this.time});
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8CBD0), width: 0.6),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
