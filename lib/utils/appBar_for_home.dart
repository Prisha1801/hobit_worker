import 'package:flutter/material.dart';
import '../api_services/location_service.dart';
import '../colors/appcolors.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import 'notification.dart';

ValueNotifier<int> notificationCount = ValueNotifier<int>(0);

class AppBarHome extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;

  const AppBarHome({super.key, this.onMenuPressed});

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning,";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon,";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening,";
    } else {
      return "Good Night,";
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = AppPreference().getString(PreferencesKey.name);
    return Container(
      width: double.infinity,
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        //color: kLightPink,
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 🔹 LEFT SIDE (Menu + Location + Name)
          Expanded(
            child: Row(
              children: [
                if (onMenuPressed != null) ...[
                  IconButton(
                    onPressed: onMenuPressed,
                    icon: const Icon(Icons.menu, color: Colors.black),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        getGreeting(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        name.isEmpty ? "User" : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              LocationStore.address.isEmpty
                                  ? "Fetching location..."
                                  : LocationStore.address,
                              style: TextStyle(
                                fontSize: 12,
                                //color: Colors.grey.shade700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 🔹 RIGHT SIDE Notification
          ValueListenableBuilder<int>(
            valueListenable: notificationCount,
            builder: (context, count, _) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications, size: 24),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(130);
}
