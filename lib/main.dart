import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const CheckInOutApp());
}

class CheckInOutApp extends StatelessWidget {
  const CheckInOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Check In / Check Out',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const CheckInOut(),
    );
  }
}

class CheckInOut extends StatefulWidget {
  const CheckInOut({super.key});

  @override
  State<CheckInOut> createState() => _CheckInOutState();
}

class _CheckInOutState extends State<CheckInOut> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(-13.9865, 33.7681);

  List<Map<String, dynamic>> checkInOutData = [];
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission().then((_) {
      _getCurrentLocation();
    });
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location Permission denied')),
        );
        return;
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateMapLocation(position);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error getting location')),
      );
    }
  }

  void _updateMapLocation(Position position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

// check in
  void _checkIn(Position position) {
    checkInOutData.add({
      'checkIn': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'time': DateTime.now().toString(),
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checked in at ${DateTime.now()}')),
    );
    _addMarker(LatLng(position.latitude, position.longitude), 'checkIn');
  }

// check out
  void _checkOut(Position position) {
    checkInOutData.add({
      'checkOut': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'time': DateTime.now().toString(),
      },
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checked out at ${DateTime.now()}')),
    );
    _addMarker(LatLng(position.latitude, position.longitude), 'checkOut');
  }

  void _addMarker(LatLng position, String type) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(type + position.toString()),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(type == 'checkIn'
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed),
          infoWindow:
              InfoWindow(title: type == 'checkIn' ? 'Check-In' : 'Check-Out'),
        ),
      );
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In / Check Out')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMapLocation(Position(
                latitude: _currentLocation.latitude,
                longitude: _currentLocation.longitude,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              ));
            },
            onTap: _onMapTap,
            myLocationEnabled: true,
            markers: _markers,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: () async {
                    try {
                      Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high);
                      _checkIn(position);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to check in.')),
                      );
                    }
                  },
                  tooltip: 'Check In',
                  child: const Icon(Icons.check),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () async {
                    try {
                      Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high);
                      _checkOut(position);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to check out.')),
                      );
                    }
                  },
                  tooltip: 'Check Out',
                  child: const Icon(Icons.exit_to_app),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
