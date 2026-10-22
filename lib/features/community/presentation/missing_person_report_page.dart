import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class MissingPersonReportPage extends StatefulWidget {
  const MissingPersonReportPage({super.key});

  @override
  State<MissingPersonReportPage> createState() =>
      _MissingPersonReportPageState();
}

class _MissingPersonReportPageState extends State<MissingPersonReportPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  final _houseController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;

  double? _latitude;
  double? _longitude;

  String _locationMethod = 'manual';
  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please turn on Location Services.'),
          ),
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Location permission was denied.'),
          ),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is permanently denied. '
              'Enable it from phone settings.',
            ),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMethod = 'current';
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Current location selected: '
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Unable to get location: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _pinOnMap() async {
    LatLng initialLocation;

    if (_latitude != null && _longitude != null) {
      initialLocation = LatLng(_latitude!, _longitude!);
    } else {
      try {
        final serviceEnabled =
            await Geolocator.isLocationServiceEnabled();

        if (serviceEnabled) {
          LocationPermission permission =
              await Geolocator.checkPermission();

          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            final position =
                await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );

            initialLocation = LatLng(
              position.latitude,
              position.longitude,
            );
          } else {
            initialLocation = const LatLng(20.5937, 78.9629);
          }
        } else {
          initialLocation = const LatLng(20.5937, 78.9629);
        }
      } catch (_) {
        initialLocation = const LatLng(20.5937, 78.9629);
      }
    }

    if (!mounted) return;

    final selectedLocation = await showDialog<LatLng>(
      context: context,
      builder: (_) => _MissingPersonLocationPicker(
        initialLocation: initialLocation,
      ),
    );

    if (selectedLocation == null || !mounted) return;

    setState(() {
      _latitude = selectedLocation.latitude;
      _longitude = selectedLocation.longitude;
      _locationMethod = 'map';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location selected: '
          '${selectedLocation.latitude.toStringAsFixed(5)}, '
          '${selectedLocation.longitude.toStringAsFixed(5)}',
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image == null || !mounted) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  Future<void> _pickFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image == null || !mounted) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the last known location using GPS or the map.',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before submitting a report.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? photoBase64;

      if (_selectedImage != null) {
        final imageBytes = await _selectedImage!.readAsBytes();
        photoBase64 = base64Encode(imageBytes);
      }

      final reportId = FirebaseFirestore.instance
          .collection('missing_person_reports')
          .doc()
          .id;

      final reportData = {
        'reportId': reportId,
        'citizenId': user.uid,
        'citizenEmail': user.email ?? '',

        'personName': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'description': _descriptionController.text.trim(),
        'contactNumber': _phoneController.text.trim(),

        'houseStreet': _houseController.text.trim(),
        'areaLocality': _areaController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'landmark': _landmarkController.text.trim(),

        'latitude': _latitude,
        'longitude': _longitude,
        'locationMethod': _locationMethod,

        'photoAttached': _selectedImage != null,
        'photoBase64': photoBase64,

        'status': 'unverified',
        'confirmationCount': 0,
        'confirmedBy': [],

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('missing_person_reports')
          .doc(reportId)
          .set(reportData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing person report submitted successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit report: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Missing Person'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Provide accurate details about the missing person '
                          'and where they were last seen.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _sectionTitle(
                  'Missing Person Details',
                  Icons.person_outline,
                ),

                _textField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter the missing person\'s name',
                ),

                _textField(
                  controller: _ageController,
                  label: 'Age',
                  hint: 'Enter age',
                  keyboardType: TextInputType.number,
                ),

                _textField(
                  controller: _descriptionController,
                  label: 'Identifying Details',
                  hint:
                      'Clothing, appearance, identification marks, etc.',
                  maxLines: 4,
                ),

                const SizedBox(height: 10),

                _sectionTitle(
                  'Photo',
                  Icons.camera_alt_outlined,
                ),

                if (_selectedImage != null)
                  Container(
                    width: double.infinity,
                    height: 220,
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _sectionTitle(
                  'Last Known Location',
                  Icons.location_on_outlined,
                ),

                const Text(
                  'Select where the person was last seen. '
                  'You can use GPS, choose a point on the map, '
                  'or enter the address manually.',
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isGettingLocation
                            ? null
                            : _useCurrentLocation,
                        icon: _isGettingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Current Location'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pinOnMap,
                        icon: const Icon(Icons.pin_drop),
                        label: const Text('Pin on Map'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _locationMethod == 'current'
                            ? Icons.my_location
                            : _locationMethod == 'map'
                                ? Icons.location_pin
                                : Icons.edit_location_alt,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _latitude != null && _longitude != null
                              ? 'Location selected: '
                                  '${_latitude!.toStringAsFixed(5)}, '
                                  '${_longitude!.toStringAsFixed(5)}'
                              : 'Enter address manually or select a location',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _textField(
                  controller: _houseController,
                  label: 'House / Street',
                  hint: 'Enter house number and street',
                  required: false,
                ),

                _textField(
                  controller: _areaController,
                  label: 'Area / Locality',
                  hint: 'Enter area or locality',
                  required: false,
                ),

                _textField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'Enter city',
                  required: false,
                ),

                _textField(
                  controller: _districtController,
                  label: 'District',
                  hint: 'Enter district',
                  required: false,
                ),

                _textField(
                  controller: _stateController,
                  label: 'State',
                  hint: 'Enter state',
                  required: false,
                ),

                _textField(
                  controller: _pincodeController,
                  label: 'Pincode',
                  hint: 'Enter pincode',
                  keyboardType: TextInputType.number,
                  required: false,
                ),

                _textField(
                  controller: _landmarkController,
                  label: 'Nearby Landmark',
                  hint: 'Enter a nearby landmark',
                  required: false,
                ),

                const SizedBox(height: 14),

                _sectionTitle(
                  'Contact Information',
                  Icons.phone_outlined,
                ),

                _textField(
                  controller: _phoneController,
                  label: 'Contact Number',
                  hint: 'Enter a number authorities can contact',
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReport,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting...'
                          : 'Submit Missing Person Report',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingPersonLocationPicker extends StatefulWidget {
  final LatLng initialLocation;

  const _MissingPersonLocationPicker({
    required this.initialLocation,
  });

  @override
  State<_MissingPersonLocationPicker> createState() =>
      _MissingPersonLocationPickerState();
}

class _MissingPersonLocationPickerState
    extends State<_MissingPersonLocationPicker> {
  late LatLng _selectedLocation;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on Location Services.'),
          ),
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selectedLocation = location;
      });

      _mapController.move(location, 17);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get current location: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Last Known Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialLocation,
                  initialZoom: 15,
                  onTap: (_, point) {
                    setState(() {
                      _selectedLocation = point;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.resqnet.app',
                  ),

                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation,
                        width: 55,
                        height: 55,
                        child: const Icon(
                          Icons.location_pin,
                          size: 50,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _moveToCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Current Location'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'Zoom in',
                        onPressed: () {
                          _mapController.move(
                            _selectedLocation,
                            _mapController.camera.zoom + 1,
                          );
                        },
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Zoom out',
                        onPressed: () {
                          _mapController.move(
                            _selectedLocation,
                            _mapController.camera.zoom - 1,
                          );
                        },
                        icon: const Icon(Icons.remove),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _selectedLocation,
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}