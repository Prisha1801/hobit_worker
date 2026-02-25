// import 'dart:async';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
//
// class CustomerRouteMap extends StatefulWidget {
//   final double customerLat;
//   final double customerLng;
//   final String address;
//
//   const CustomerRouteMap({
//     super.key,
//     required this.customerLat,
//     required this.customerLng,
//     required this.address,
//   });
//
//   @override
//   State<CustomerRouteMap> createState() => _CustomerRouteMapState();
// }
//
// class _CustomerRouteMapState extends State<CustomerRouteMap> {
//   LatLng? workerLatLng;
//   List<LatLng> routePoints = [];
//   StreamSubscription<Position>? positionStream;
//
//   @override
//   void initState() {
//     super.initState();
//     startWorkerLocation();
//   }
//
//   void startWorkerLocation() async {
//     positionStream = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 10,
//       ),
//     ).listen((pos) async {
//       workerLatLng = LatLng(pos.latitude, pos.longitude);
//
//       routePoints = await fetchRoute(
//         workerLatLng!,
//         LatLng(widget.customerLat, widget.customerLng),
//       );
//
//       setState(() {});
//     });
//   }
//
//   Future<List<LatLng>> fetchRoute(
//       LatLng origin, LatLng destination) async {
//     final dio = Dio();
//     final res = await dio.get(
//       'https://maps.googleapis.com/maps/api/directions/json',
//       queryParameters: {
//         'origin': '${origin.latitude},${origin.longitude}',
//         'destination': '${destination.latitude},${destination.longitude}',
//         'key': 'AIzaSyBGv9znbx4hAdCp_6YK0-HO2XVKI4ZXALk',
//       },
//     );
//
//     final encoded =
//     res.data['routes'][0]['overview_polyline']['points'];
//     return decodePolyline(encoded);
//   }
//
//   List<LatLng> decodePolyline(String encoded) {
//     List<LatLng> poly = [];
//     int index = 0, lat = 0, lng = 0;
//
//     while (index < encoded.length) {
//       int shift = 0, result = 0;
//       int b;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//
//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//
//       poly.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return poly;
//   }
//
//   @override
//   void dispose() {
//     positionStream?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (workerLatLng == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: Text("Customer Route")),
//       body: GoogleMap(
//         initialCameraPosition: CameraPosition(
//           target: workerLatLng!,
//           zoom: 14,
//         ),
//         myLocationEnabled: true,
//         markers: {
//           Marker(
//             markerId: const MarkerId("worker"),
//             position: workerLatLng!,
//             icon: BitmapDescriptor.defaultMarkerWithHue(
//               BitmapDescriptor.hueBlue,
//             ),
//           ),
//           Marker(
//             markerId: const MarkerId("customer"),
//             position:
//             LatLng(widget.customerLat, widget.customerLng),
//           ),
//         },
//         polylines: {
//           Polyline(
//             polylineId: const PolylineId("route"),
//             color: Colors.green,
//             width: 5,
//             points: routePoints,
//           ),
//         },
//       ),
//     );
//   }
// }


// import 'dart:async';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import '../colors/appcolors.dart';
//
// class CustomerRouteMap extends StatefulWidget {
//   final double customerLat;
//   final double customerLng;
//   final String address;
//
//   const CustomerRouteMap({
//     super.key,
//     required this.customerLat,
//     required this.customerLng,
//     required this.address,
//   });
//
//   @override
//   State<CustomerRouteMap> createState() => _CustomerRouteMapState();
// }
//
// class _CustomerRouteMapState extends State<CustomerRouteMap> {
//   LatLng? workerLatLng;
//   List<LatLng> routePoints = [];
//   StreamSubscription<Position>? positionStream;
//
//   String remainingDistance = "";
//   String remainingTime = "";
//
//   @override
//   void initState() {
//     super.initState();
//     startWorkerLocation();
//   }
//
//   /// 🔥 Live worker location tracking
//   void startWorkerLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//
//     positionStream = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 10, // meters
//       ),
//     ).listen((pos) async {
//       workerLatLng = LatLng(pos.latitude, pos.longitude);
//
//       routePoints = await fetchRoute(
//         workerLatLng!,
//         LatLng(widget.customerLat, widget.customerLng),
//       );
//
//       setState(() {});
//     });
//   }
//
//   /// 🔥 Fetch route + distance + ETA
//   Future<List<LatLng>> fetchRoute(
//       LatLng origin,
//       LatLng destination,
//       ) async {
//     final dio = Dio();
//
//     final res = await dio.get(
//       'https://maps.googleapis.com/maps/api/directions/json',
//       queryParameters: {
//         'origin': '${origin.latitude},${origin.longitude}',
//         'destination': '${destination.latitude},${destination.longitude}',
//         'mode': 'driving',
//         'key': 'AIzaSyBGv9znbx4hAdCp_6YK0-HO2XVKI4ZXALk',
//       },
//     );
//
//     final route = res.data['routes'][0];
//     final leg = route['legs'][0];
//
//     // 🔥 Remaining distance & time
//     remainingDistance = leg['distance']['text']; // e.g. 1.2 km
//     remainingTime = leg['duration']['text']; // e.g. 5 mins
//
//     final encodedPolyline = route['overview_polyline']['points'];
//     return decodePolyline(encodedPolyline);
//   }
//
//   /// 🔥 Polyline decode
//   List<LatLng> decodePolyline(String encoded) {
//     List<LatLng> poly = [];
//     int index = 0, lat = 0, lng = 0;
//
//     while (index < encoded.length) {
//       int shift = 0, result = 0;
//       int b;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//
//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//
//       poly.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return poly;
//   }
//
//   @override
//   void dispose() {
//     positionStream?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (workerLatLng == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: kWhite,
//       appBar: AppBar(title: const Text("Customer Route")),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: workerLatLng!,
//               zoom: 14,
//             ),
//             myLocationEnabled: true,
//             markers: {
//               Marker(
//                 markerId: const MarkerId("worker"),
//                 position: workerLatLng!,
//                 icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueBlue,
//                 ),
//               ),
//               Marker(
//                 markerId: const MarkerId("customer"),
//                 position:
//                 LatLng(widget.customerLat, widget.customerLng),
//               ),
//             },
//             polylines: {
//               Polyline(
//                 polylineId: const PolylineId("route"),
//                 color: Colors.green,
//                 width: 5,
//                 points: routePoints,
//               ),
//             },
//           ),
//
//           /// 🔥 Distance & ETA Card (Google Maps style)
//           Positioned(
//             bottom: 20,
//             left: 16,
//             right: 16,
//             child: Card(
//               color: kWhite,
//               elevation: 8,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   mainAxisAlignment:
//                   MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           "Remaining Distance",
//                           style: TextStyle(fontSize: 12),
//                         ),
//                         Text(
//                           remainingDistance,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Column(
//                       crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           "Estimated Time",
//                           style: TextStyle(fontSize: 12),
//                         ),
//                         Text(
//                           remainingTime,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hobit_worker/utils/app_bar.dart';
import '../colors/appcolors.dart';

class CustomerRouteMap extends StatefulWidget {
  final double customerLat;
  final double customerLng;
  final String address;

  const CustomerRouteMap({
    super.key,
    required this.customerLat,
    required this.customerLng,
    required this.address,
  });

  @override
  State<CustomerRouteMap> createState() => _CustomerRouteMapState();
}

class _CustomerRouteMapState extends State<CustomerRouteMap> {
  LatLng? workerLatLng;
  LatLng? lastPosition;

  List<LatLng> routePoints = [];
  StreamSubscription<Position>? positionStream;

  String remainingDistance = "";
  String remainingTime = "";

  BitmapDescriptor? bikeIcon;
  double markerRotation = 0.0;

  double currentZoom = 15;

  @override
  void initState() {
    super.initState();
    updateMarkerIcon(currentZoom);
    startWorkerLocation();
  }

  // 🔥 Resize image based on zoom (ICON behaviour)
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final byteData =
    await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // 🔥 Update icon size when zoom changes
  Future<void> updateMarkerIcon(double zoom) async {
    int size;
    if (zoom >= 18) {
      size = 120;
    } else if (zoom >= 16) {
      size = 100;
    } else if (zoom >= 14) {
      size = 80;
    } else {
      size = 60;
    }

    final bytes =
    await getBytesFromAsset('assets/images/riderpng.png', size);
    bikeIcon = BitmapDescriptor.fromBytes(bytes);

    if (mounted) setState(() {});
  }

  /// 🔥 Start live tracking
  void startWorkerLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) async {
      final newPos = LatLng(pos.latitude, pos.longitude);

      if (lastPosition != null) {
        markerRotation = getBearing(lastPosition!, newPos);
      }

      lastPosition = newPos;
      workerLatLng = newPos;

      routePoints = await fetchRoute(
        newPos,
        LatLng(widget.customerLat, widget.customerLng),
      );

      setState(() {});
    });
  }

  /// 🔥 Directions API
  Future<List<LatLng>> fetchRoute(
      LatLng origin, LatLng destination) async {
    final dio = Dio();

    final res = await dio.get(
      'https://maps.googleapis.com/maps/api/directions/json',
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'key': 'AIzaSyAKycpWAllnNwoMkwNncDOPS_y6KV0kLZY',
      },
    );

    final route = res.data['routes'][0];
    final leg = route['legs'][0];

    remainingDistance = leg['distance']['text'];
    remainingTime = leg['duration']['text'];

    return decodePolyline(route['overview_polyline']['points']);
  }

  /// 🔥 Polyline decode
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  /// 🔥 Bearing for rotation
  double getBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLon = (end.longitude - start.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final brng = math.atan2(y, x);
    return (brng * 180 / math.pi + 360) % 360;
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (workerLatLng == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: kWhite,
     appBar: CommonAppBar(title: 'Customer Route'),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: workerLatLng!,
              zoom: currentZoom,
            ),
            myLocationEnabled: true,
            onCameraMove: (position) {
              if ((position.zoom - currentZoom).abs() > 0.3) {
                currentZoom = position.zoom;
                updateMarkerIcon(currentZoom);
              }
            },
            markers: {
              Marker(
                markerId: const MarkerId("worker"),
                position: workerLatLng!,
                rotation: markerRotation,
                flat: true,
                anchor: const Offset(0.5, 0.5),
                icon: bikeIcon ?? BitmapDescriptor.defaultMarker,
              ),
              Marker(
                markerId: const MarkerId("customer"),
                position:
                LatLng(widget.customerLat, widget.customerLng),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId("route"),
                color: Colors.green,
                width: 5,
                points: routePoints,
              ),
            },
          ),

          /// 🔥 Distance + ETA Card
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              color: kWhite,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text("Remaining Distance",
                            style: TextStyle(fontSize: 12)),
                        Text(
                          remainingDistance,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text("Estimated Time",
                            style: TextStyle(fontSize: 12)),
                        Text(
                          remainingTime,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}