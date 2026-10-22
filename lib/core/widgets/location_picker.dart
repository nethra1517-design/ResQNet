import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Future<LatLng?> showLocationPicker(
  BuildContext context, {
  double? latitude,
  double? longitude,
}) {
  return showDialog<LatLng>(
    context: context,
    builder: (_) => LocationPickerDialog(
      initialLocation: latitude != null && longitude != null
          ? LatLng(latitude, longitude)
          : null,
    ),
  );
}

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedLocation =
        widget.initialLocation ?? const LatLng(20.5937, 78.9622);
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF087F8C);

    return AlertDialog(
      title: const Text('Pin location on map'),
      content: SizedBox(
        width: 600,
        height: 420,
        child: Column(
          children: [
            const Text('Tap the map to place or move the pin.'),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: selectedLocation,
                    initialZoom: 13,
                    onTap: (_, point) {
                      setState(() => selectedLocation = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.resqnet',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${selectedLocation.latitude.toStringAsFixed(6)}\n'
              'Lng: ${selectedLocation.longitude.toStringAsFixed(6)}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedLocation),
          style: ElevatedButton.styleFrom(
            backgroundColor: teal,
            foregroundColor: Colors.white,
          ),
          child: const Text('USE THIS LOCATION'),
        ),
      ],
    );
  }
}