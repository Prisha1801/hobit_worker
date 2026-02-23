import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
  List<LatLng> routePoints = [];
  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    startWorkerLocation();
  }

  void startWorkerLocation() async {
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) async {
      workerLatLng = LatLng(pos.latitude, pos.longitude);

      routePoints = await fetchRoute(
        workerLatLng!,
        LatLng(widget.customerLat, widget.customerLng),
      );

      setState(() {});
    });
  }

  Future<List<LatLng>> fetchRoute(
      LatLng origin, LatLng destination) async {
    final dio = Dio();
    final res = await dio.get(
      'https://maps.googleapis.com/maps/api/directions/json',
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'key': 'AIzaSyBGv9znbx4hAdCp_6YK0-HO2XVKI4ZXALk',
      },
    );

    final encoded =
    res.data['routes'][0]['overview_polyline']['points'];
    return decodePolyline(encoded);
  }

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
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
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
      appBar: AppBar(title: Text("Customer Route")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: workerLatLng!,
          zoom: 14,
        ),
        myLocationEnabled: true,
        markers: {
          Marker(
            markerId: const MarkerId("worker"),
            position: workerLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
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
    );
  }
}