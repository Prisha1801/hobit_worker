import 'package:flutter/material.dart';
import '../api_services/api_services.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import 'package:dio/dio.dart';

class RescheduleHistoryDialog extends StatefulWidget {
  final int bookingId;

  const RescheduleHistoryDialog({super.key, required this.bookingId});

  @override
  State<RescheduleHistoryDialog> createState() =>
      _RescheduleHistoryDialogState();
}

class _RescheduleHistoryDialogState extends State<RescheduleHistoryDialog> {
  List history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final token = AppPreference().getString(PreferencesKey.token);

      final res = await ApiService.getRequest(
        '/api/customer/bookings/${widget.bookingId}/reschedule-history',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      history = res.data['data']['history'] ?? [];
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          children: [

            /// TITLE
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Reschedule History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),

            const Divider(),

            /// BODY
            if (loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              )
            else if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("No reschedule history found"),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {

                    final item = history[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xffF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// OLD DATE
                          Text(
                            "Old Date: ${item['old_date']} (${item['old_time_slot']})",
                            style: const TextStyle(fontSize: 13),
                          ),

                          const SizedBox(height: 6),

                          /// NEW DATE
                          Text(
                            "New Date: ${item['new_date']} (${item['new_time_slot']})",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 6),

                          /// REASON
                          Text(
                            "Reason: ${item['reason']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Rescheduled At: ${item['created_at']}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}