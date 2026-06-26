import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import '../api_services/notification_services.dart';
import '../l10n/app_localizations.dart';
import '../attendance/screens/attendance_history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/my_bookings.dart';
import '../screens/profile.dart';
import '../screens/coordinator_dashboard.dart';
import '../screens/contractor_dashboard.dart';
import '../prefs/app_preference.dart';
import '../prefs/preference_key.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {

  @override
  void initState() {
    super.initState();

    // ✅ If the app was cold-started by tapping a notification, open the
    // NotificationScreen on top of MainScreen once the first frame is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (LocalNotificationService.launchedFromNotification) {
        LocalNotificationService.launchedFromNotification = false;
        LocalNotificationService.openNotificationsPage();
      }
    });
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    bool? exitApp = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(loc.exitApp,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Text(loc.exitMessage,
            style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.no,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kkblack,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.yes),
          ),
        ],
      ),
    );
    return exitApp ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final String savedRole = AppPreference().getString(PreferencesKey.role).toLowerCase().trim();
    
    debugPrint("🔍 Current User Role detected in MainScreen: '$savedRole'");

    final bool isCoordinator = savedRole == 'coordinators' || 
                               savedRole == 'coordinator' || 
                               savedRole == 'co-ordinators' || 
                               savedRole == 'co-ordinator';

    // ✅ If Coordinator, return Dashboard WITHOUT Scaffold/BottomNav from MainScreen
    if (isCoordinator) {
      return const CoordinatorDashboard();
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    Widget getHomeScreen() {
      if (savedRole == 'contractors' || savedRole == 'contractor') {
        return const ContractorDashboard();
      } else {
        return const HomeScreen();
      }
    }

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: [
            getHomeScreen(),
            const BookingsScreen(),
            const AttendanceHistoryScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: currentIndex,
            onTap: (index) {
              ref.read(bottomNavIndexProvider.notifier).state = index;
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: kkblack,
            //unselectedItemColor: Colors.grey,
            unselectedItemColor: Colors.black,
            selectedFontSize: screenHeight * 0.015,
            unselectedFontSize: screenHeight * 0.013,
            selectedIconTheme: IconThemeData(size: screenHeight * 0.035),
            unselectedIconTheme: IconThemeData(size: screenHeight * 0.03),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: loc.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_outlined),
                activeIcon: const Icon(Icons.calendar_month),
                label: loc.bookings,
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.access_time_outlined),
                activeIcon: Icon(Icons.access_time_filled),
                label: 'Attendance',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: loc.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
