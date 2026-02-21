
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hobit_worker/utils/app_bar.dart';
import '../api_services/location_service.dart';
import '../utils/bottom_nav_bar.dart';

class ConfirmLocationScreen extends StatefulWidget {
  const ConfirmLocationScreen({super.key});

  @override
  State<ConfirmLocationScreen> createState() => _ConfirmLocationScreenState();
}

class _ConfirmLocationScreenState extends State<ConfirmLocationScreen> {
  LatLng? currentLatLng;
  String address = "Fetching location...";
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    final pos = await LocationService.getCurrentLocation();

    currentLatLng = LatLng(pos.latitude, pos.longitude);
    LocationStore.lat = pos.latitude;
    LocationStore.lng = pos.longitude;

    final placemarks =
    await placemarkFromCoordinates(pos.latitude, pos.longitude);

    final place = placemarks.first;

    final landmark = place.name ?? place.street ?? "";
    final subArea = place.subLocality ?? "";
    final city = place.locality ?? "";
    final state = place.administrativeArea ?? "";

    final fullAddress = [
      landmark,
      subArea,
      city,
      state,
    ].where((e) => e.isNotEmpty).join(", ");

    /// ✅ Update address everywhere
    LocationStore.address = fullAddress;
    address = fullAddress;

    /// 🔵 BLUE MARKER AT USER LOCATION
    markers = {
      Marker(
        markerId: const MarkerId("current_location"),
        position: currentLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure, // 🔵 BLUE
        ),
      ),
    };

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (currentLatLng == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(title: 'Confirm Your Address'),
      body: Stack(
        children: [
          /// 🗺 GOOGLE MAP

          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLatLng!,
              zoom: 16,
            ),

            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,

            /// 🔥 THIS IS THE FIX
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
              ),
            },
          ),

          /// 📍 ADDRESS CARD (REAL ADDRESS)
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ✅ CONFIRM BUTTON
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // 🖤 BLACK BUTTON
                  foregroundColor: Colors.white, // 🤍 WHITE TEXT
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                },
                child: const Text(
                  "Confirm location",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
