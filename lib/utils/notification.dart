import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool showUnread = false;

  final List<Map<String, dynamic>> notifications = [
    {
      "title": "Booking Confirmed",
      "subtitle":
      "Your booking has been confirmed. The professional will arrive on time.",
      "buttonText": "View Details",
      "isUnread": true,
    },
    {
      "title": "Service Started",
      "subtitle": "Your service has started and is currently in progress.",
      "buttonText": "Track Service",
      "isUnread": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = showUnread
        ? notifications.where((n) => n['isUnread'] == true).toList()
        : notifications;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ===== ALL / UNREAD TABS =====
            Row(
              children: [
                _tabItem(
                  title: "All",
                  selected: !showUnread,
                  onTap: () {
                    setState(() => showUnread = false);
                  },
                ),
                const SizedBox(width: 8),
                _tabItem(
                  title: "Unread",
                  selected: showUnread,
                  onTap: () {
                    setState(() => showUnread = true);
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ===== LIST =====
            Expanded(
              child: filteredNotifications.isEmpty
                  ? const Center(
                child: Text(
                  "No notifications",
                  style: TextStyle(color: Colors.black54),
                ),
              )
                  : ListView.builder(
                itemCount: filteredNotifications.length,
                itemBuilder: (context, index) {
                  return _notificationCard(
                    filteredNotifications[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== TAB =====
  Widget _tabItem({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  /// ===== NOTIFICATION CARD =====
  Widget _notificationCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// UNREAD DOT
          if (item['isUnread'])
            Container(
              margin: const EdgeInsets.only(top: 6, right: 10),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 18),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['subtitle'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                /// ACTION BUTTON
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    item['buttonText'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
