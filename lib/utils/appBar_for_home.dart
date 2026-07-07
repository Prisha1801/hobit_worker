import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../api_services/location_service.dart';
import '../colors/appcolors.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';
import 'notification.dart';

ValueNotifier<int> notificationCount = ValueNotifier<int>(0);

class AppBarHome extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onEmergencyPressed;

  const AppBarHome({super.key, this.onMenuPressed, this.onEmergencyPressed});

  String getGreeting(AppLocalizations loc) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return loc.abhGoodMorning;
    } else if (hour >= 12 && hour < 17) {
      return loc.abhGoodAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return loc.abhGoodEvening;
    } else {
      return loc.abhGoodNight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
                        getGreeting(loc),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        name.isEmpty ? loc.abhUser : name,
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
                                  ? loc.fetchingLocation
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

          /// 🔹 RIGHT SIDE Icons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Alert / Warning Icon
              GestureDetector(
                onTap: onEmergencyPressed,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              /// Notification Bell
              ValueListenableBuilder<int>(
                valueListenable: notificationCount,
                builder: (context, count, _) {
                  return Stack(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications_outlined, size: 22),
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(130);
}
