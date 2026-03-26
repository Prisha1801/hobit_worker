// import 'package:flutter/material.dart';
// import 'package:hobit_worker/colors/appcolors.dart';
// import '../l10n/app_localizations.dart';
// import '../screens/home_screen.dart';
// import '../screens/my_bookings.dart';
// import '../screens/profile.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
//
// final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
//
// class MainScreen extends ConsumerWidget {
//   const MainScreen({Key? key}) : super(key: key);
//
//   Future<bool> _onWillPop(BuildContext context) async {
//
//     final loc = AppLocalizations.of(context)!;
//
//     bool? exitApp = await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//
//         title: Text(
//           loc.exitApp,
//           style: const TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//
//         content: Text(
//           loc.exitMessage,
//           style: const TextStyle(color: Colors.black87),
//         ),
//
//         actions: [
//
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(false);
//             },
//             child: Text(
//               loc.no,
//               style: const TextStyle(
//                 color: Colors.black,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: kkblack,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () {
//               Navigator.of(context).pop(true);
//             },
//             child: Text(loc.yes),
//           ),
//         ],
//       ),
//     );
//
//     return exitApp ?? false;
//   }
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final loc = AppLocalizations.of(context)!;
//     final currentIndex = ref.watch(bottomNavIndexProvider);
//
//     return WillPopScope(
//       onWillPop: () => _onWillPop(context),
//       child: Scaffold(
//         body: IndexedStack(
//           index: currentIndex,
//           children: const [
//             HomeScreen(),
//             BookingsScreen(),
//             ProfileScreen(),
//           ],
//         ),
//
//         bottomNavigationBar: SizedBox(
//           height: 80,
//           child: BottomNavigationBar(
//             backgroundColor: Colors.white,
//             currentIndex: currentIndex,
//             onTap: (index) {
//               ref.read(bottomNavIndexProvider.notifier).state = index;
//             },
//             type: BottomNavigationBarType.fixed,
//             selectedItemColor: kkblack,
//             unselectedItemColor: Colors.grey,
//             items: [
//               BottomNavigationBarItem(
//                 icon: const Icon(Icons.home),
//                 label: loc.home,
//               ),
//               BottomNavigationBarItem(
//                 icon: const Icon(Icons.calendar_month),
//                 label: loc.bookings,
//               ),
//               BottomNavigationBarItem(
//                 icon: const Icon(Icons.person),
//                 label: loc.profile,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import '../l10n/app_localizations.dart';
import '../screens/home_screen.dart';
import '../screens/my_bookings.dart';
import '../screens/profile.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({Key? key}) : super(key: key);

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
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // ✅ Screen size se responsive height
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: const [
            HomeScreen(),
            BookingsScreen(),
            ProfileScreen(),
          ],
        ),

        // ✅ Responsive Bottom Nav
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
            unselectedItemColor: Colors.grey,

            // ✅ Responsive font size
            selectedFontSize: screenHeight * 0.015,  // ~12-13px most devices
            unselectedFontSize: screenHeight * 0.013,

            // ✅ Icon size bhi responsive
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