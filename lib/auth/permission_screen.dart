import 'package:flutter/material.dart';
import '../colors/appcolors.dart';
import '../l10n/app_localizations.dart';
import '../screens/map_screen.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

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
            Image.asset('assets/images/Address.png', height: 220),
            const SizedBox(height: 30),
            Text(
              loc.allowLocationTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConfirmLocationScreen(),
                    ),
                  );
                },
                child: Text(loc.allowLocationButton, style: const TextStyle(color: kWhite,  fontSize: 15,
                  fontWeight: FontWeight.w600,),),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

