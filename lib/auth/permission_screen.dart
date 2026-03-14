// import 'package:flutter/material.dart';
// import '../colors/appcolors.dart';
// import '../l10n/app_localizations.dart';
// import '../screens/map_screen.dart';
//
// class LocationPermissionScreen extends StatelessWidget {
//   const LocationPermissionScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final loc = AppLocalizations.of(context)!;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             const SizedBox(height: 80),
//             Image.asset('assets/images/Address.png', height: 220),
//             const SizedBox(height: 30),
//             Text(
//               loc.allowLocationTitle,
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 10),
//             Text(
//              loc.allowLocationDesc,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.black54),
//             ),
//             const Spacer(),
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: kkblack,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(5),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const ConfirmLocationScreen(),
//                     ),
//                   );
//                 },
//                 child: Text(loc.allowLocationButton, style: const TextStyle(color: kWhite,  fontSize: 15,
//                   fontWeight: FontWeight.w600,),),
//               ),
//             ),
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }
// }
//


import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../colors/appcolors.dart';
import '../l10n/app_localizations.dart';
import '../screens/map_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {

  Future<void> _checkLocation() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    /// 🔴 Location OFF → open settings
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    /// Permission check
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    /// Permission denied
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {

      await Geolocator.openAppSettings();
      return;
    }

    /// ✅ Location ON + Permission Granted
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfirmLocationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 80),

            Image.asset(
              'assets/images/Address.png',
              height: 220,
            ),

            const SizedBox(height: 30),

            Text(
              loc.allowLocationTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              loc.allowLocationDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kkblack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),

                /// 🔥 BUTTON PRESS → CHECK LOCATION
                onPressed: _checkLocation,

                child: Text(
                  loc.allowLocationButton,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}