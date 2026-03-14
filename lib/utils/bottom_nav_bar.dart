import 'package:flutter/material.dart';
import 'package:hobit_worker/colors/appcolors.dart';
import '../l10n/app_localizations.dart';
import '../screens/home_screen.dart';
import '../screens/my_bookings.dart';
import '../screens/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({Key? key}) : super(key: key);

  Future<bool> _onWillPop(BuildContext context) async {

    final loc = AppLocalizations.of(context)!;

    bool? exitApp = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        title: Text(
          loc.exitApp,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        content: Text(
          loc.exitMessage,
          style: const TextStyle(color: Colors.black87),
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(
              loc.no,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kkblack,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
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

        bottomNavigationBar: SizedBox(
          height: 80,
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: currentIndex,
            onTap: (index) {
              ref.read(bottomNavIndexProvider.notifier).state = index;
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: kkblack,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: loc.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month),
                label: loc.bookings,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: loc.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// class MainScreen extends ConsumerWidget {
//   const MainScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final loc = AppLocalizations.of(context)!;
//     final currentIndex = ref.watch(bottomNavIndexProvider);
//
//     return Scaffold(
//       body: IndexedStack(
//         index: currentIndex,
//         children: const [
//           HomeScreen(),     // 0
//           BookingsScreen(), // 1
//           //WalletScreen(),   // 2
//           ProfileScreen(),  // 3
//         ],
//       ),
//
//       bottomNavigationBar: SizedBox(
//         height: 80,
//         child: BottomNavigationBar(
//           backgroundColor: Colors.white,
//           currentIndex: currentIndex,
//           onTap: (index) {
//             ref.read(bottomNavIndexProvider.notifier).state = index;
//           },
//           type: BottomNavigationBarType.fixed,
//           selectedItemColor: Colors.black,
//           unselectedItemColor: Colors.grey,
//           items: [
//             BottomNavigationBarItem(
//               icon: const Icon(Icons.home),
//               label: loc.home,
//             ),
//             BottomNavigationBarItem(
//               icon: const Icon(Icons.calendar_month),
//               label: loc.bookings,
//             ),
//             // BottomNavigationBarItem(
//             //   icon: Icon(Icons.account_balance_wallet),
//             //   label: 'Wallet',
//             // ),
//             BottomNavigationBarItem(
//               icon: const Icon(Icons.person),
//               label: loc.profile,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
