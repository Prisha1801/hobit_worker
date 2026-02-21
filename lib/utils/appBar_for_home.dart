import 'package:flutter/material.dart';
import '../api_services/location_service.dart';
import '../colors/appcolors.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import 'notification.dart';

class AppBarHome extends StatelessWidget
    implements PreferredSizeWidget {

  const AppBarHome({super.key});

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
        color: kLightPink,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          /// 🔹 LEFT SIDE (Location + Name)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                const SizedBox(width: 4),

                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      /// Greeting
                      Text(
                        getGreeting(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),

                      /// Name
                      Text(
                        name.isEmpty ? "User" : name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      /// 🔥 Dynamic Location Row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              LocationStore.address.isEmpty
                                  ? "Fetching location..."
                                  : LocationStore.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.black,
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(),
                ),
              );
            },
            icon: Image.asset(
              'assets/images/notification.png',
              height: 24,
              width: 24,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(130);
}
