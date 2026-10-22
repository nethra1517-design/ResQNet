import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class BlockedRoadReportPage extends StatefulWidget {
  const BlockedRoadReportPage({super.key});

  @override
  State<BlockedRoadReportPage> createState() =>
      _BlockedRoadReportPageState();
}

class _BlockedRoadReportPageState
    extends State<BlockedRoadReportPage> {
  final TextEditingController _descriptionController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;

  double? _latitude;
  double? _longitude;

  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> _getLocation() async {
    if (_isGettingLocation) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _isGettingLocation = false;
        });

        _showMessage(
          'Please enable location services.',
        );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _isGettingLocation = false;
        });

        _showMessage(
          'Location permission denied.',
        );

        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });

      _showMessage(
        'Current location captured successfully.',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isGettingLocation = false;
      });

      _showMessage(
        'Unable to get your current location.',
      );
    }
  }

  // ============================================================
  // OPEN MAP LOCATION PICKER
  // ============================================================

  Future<void> _openMapPicker() async {
    LatLng initialLocation =
        const LatLng(20.5937, 78.9629);

    // ----------------------------------------------------------
    // If a location has already been selected, open there.
    // ----------------------------------------------------------

    if (_latitude != null && _longitude != null) {
      initialLocation = LatLng(
        _latitude!,
        _longitude!,
      );
    } else {
      // --------------------------------------------------------
      // Otherwise try to get the current location.
      // If unavailable, the map opens at India.
      // --------------------------------------------------------

      try {
        final bool serviceEnabled =
            await Geolocator.isLocationServiceEnabled();

        if (serviceEnabled) {
          LocationPermission permission =
              await Geolocator.checkPermission();

          if (permission ==
              LocationPermission.denied) {
            permission =
                await Geolocator.requestPermission();
          }

          if (permission !=
                  LocationPermission.denied &&
              permission !=
                  LocationPermission.deniedForever) {
            final Position position =
                await Geolocator.getCurrentPosition(
              locationSettings:
                  const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );

            initialLocation = LatLng(
              position.latitude,
              position.longitude,
            );
          }
        }
      } catch (_) {
        // If location cannot be obtained,
        // keep India as the fallback center.
      }
    }

    if (!mounted) return;

    final LatLng? selectedLocation =
        await showDialog<LatLng>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _LocationPickerDialog(
          initialLocation: initialLocation,
        );
      },
    );

    if (!mounted || selectedLocation == null) {
      return;
    }

    setState(() {
      _latitude = selectedLocation.latitude;
      _longitude = selectedLocation.longitude;
    });

    _showMessage(
      'Report location selected successfully.',
    );
  }

  // ============================================================
  // TAKE PHOTO
  // ============================================================

  Future<void> _takePhoto() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to access the camera.',
      );
    }
  }

  // ============================================================
  // REMOVE PHOTO
  // ============================================================

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
    });
  }

  // ============================================================
  // SUBMIT REPORT
  // ============================================================

  Future<void> _submitReport() async {
    if (_isSubmitting) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in again.',
      );
      return;
    }

    if (_latitude == null ||
        _longitude == null) {
      _showMessage(
        'Please get your current location or select a location on the map.',
      );
      return;
    }

    final String description =
        _descriptionController.text.trim();

    if (description.isEmpty) {
      _showMessage(
        'Please describe what is blocking the road.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? photoBase64;

      if (_selectedImage != null) {
        final List<int> bytes =
            await _selectedImage!.readAsBytes();

        photoBase64 = base64Encode(bytes);
      }

      final DocumentReference<Map<String, dynamic>>
          reportReference = FirebaseFirestore.instance
              .collection('blocked_road_reports')
              .doc();

      await reportReference.set({
        'reportId': reportReference.id,

        'citizenId': user.uid,

        'citizenEmail': user.email ?? '',

        'description': description,

        'latitude': _latitude,

        'longitude': _longitude,

        'photoAttached':
            photoBase64 != null,

        'photoBase64':
            photoBase64,

        // New reports start as unverified
        // according to the Community Intelligence
        // Map requirement.
        'status': 'unverified',

        'confirmationCount': 0,

        'confirmedBy': [],

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Blocked road report submitted successfully.',
          ),
          backgroundColor:
              Color(0xFF087F8C),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      if (e.code == 'permission-denied') {
        _showMessage(
          'Permission denied. Please check Firestore rules.',
        );
      } else {
        _showMessage(
          'Unable to submit the report. Please try again.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to submit the report. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // LOCATION CARD
  // ============================================================

  Widget _buildLocationCard() {
    final bool hasLocation =
        _latitude != null &&
            _longitude != null;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color:
            const Color(0xFFF1F4F7),

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              const Color(0xFFE1E7EC),
        ),
      ),

      child: Column(
        children: [
          // ======================================================
          // SELECTED LOCATION
          // ======================================================

          Row(
            children: [
              Container(
                width: 45,
                height: 45,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFDDF4F5),
                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons.location_on_rounded,
                  color:
                      Color(0xFF087F8C),
                  size: 25,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: hasLocation
                    ? Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Location selected',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF166534,
                              ),
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Lat: ${_latitude!.toStringAsFixed(6)}\n'
                            'Lng: ${_longitude!.toStringAsFixed(6)}',
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF64748B,
                              ),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Location not selected',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF64748B,
                              ),
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          SizedBox(height: 3),

                          Text(
                            'Choose current location or pin a location on the map.',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF94A3B8,
                              ),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // LOCATION BUTTONS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isGettingLocation
                          ? null
                          : _getLocation,

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(
                      0xFF087F8C,
                    ),

                    side:
                        const BorderSide(
                      color:
                          Color(0xFF087F8C),
                    ),

                    minimumSize:
                        const Size(
                      0,
                      46,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),

                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Color(
                              0xFF087F8C,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons
                              .my_location_rounded,
                          size: 19,
                        ),

                  label: Text(
                    _isGettingLocation
                        ? 'Getting...'
                        : 'Current Location',
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _openMapPicker,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF087F8C,
                    ),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    minimumSize:
                        const Size(
                      0,
                      46,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),

                  icon: const Icon(
                    Icons.map_rounded,
                    size: 19,
                  ),

                  label: const Text(
                    'Pin on Map',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHOTO SECTION
  // ============================================================

  Widget _buildPhotoSection() {
    if (_selectedImage == null) {
      return InkWell(
        onTap: _takePhoto,

        borderRadius:
            BorderRadius.circular(16),

        child: Container(
          width: double.infinity,

          padding:
              const EdgeInsets.symmetric(
            vertical: 22,
            horizontal: 15,
          ),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(16),

            border: Border.all(
              color:
                  const Color(0xFFD7DEE5),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFF3E9FA),
                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons
                      .photo_camera_rounded,
                  color:
                      Color(0xFF7027A0),
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Photo Evidence',
                      style:
                          TextStyle(
                        color:
                            Color(0xFF102A43),
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Optional — take a photo of the blocked road.',
                      style:
                          TextStyle(
                        color:
                            Color(0xFF7B8794),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    Color(0xFF9AA5B1),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              const Color(0xFFD7DEE5),
        ),
      ),

      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(16),
            ),

            child: Image.file(
              _selectedImage!,

              width: double.infinity,

              height: 210,

              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),

            child: Row(
              children: [
                const Icon(
                  Icons
                      .check_circle_rounded,
                  color:
                      Color(0xFF16A34A),
                  size: 21,
                ),

                const SizedBox(width: 7),

                const Expanded(
                  child: Text(
                    'Photo attached',
                    style: TextStyle(
                      color:
                          Color(0xFF166534),
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),

                TextButton(
                  onPressed:
                      _removePhoto,

                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      color:
                          Color(0xFF087F8C),
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFEAF7F8),

        elevation: 0,

        foregroundColor:
            const Color(0xFF102A43),

        title: const Text(
          'Report Blocked Road',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // INFORMATION CARD
              // ==================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF7F8),

                  borderRadius:
                      BorderRadius.circular(22),

                  border: Border.all(
                    color:
                        const Color(0xFFC7E8EA),
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,

                      decoration:
                          const BoxDecoration(
                        color: Colors.white,
                        shape:
                            BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons
                            .do_not_disturb_on_rounded,
                        color:
                            Color(0xFF087F8C),
                        size: 29,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            'Report a Blocked Road',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF102A43,
                              ),
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Help the community by reporting roads that are blocked or inaccessible.',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF64748B,
                              ),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // DESCRIPTION
              // ==================================================

              const Text(
                'What is blocking the road?',
                style: TextStyle(
                  color:
                      Color(0xFF102A43),
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 9),

              TextField(
                controller:
                    _descriptionController,

                maxLines: 5,

                decoration:
                    InputDecoration(
                  hintText:
                      'Describe the blocked road, debris, flooding, fallen tree, damaged road, etc.',

                  hintStyle:
                      const TextStyle(
                    color:
                        Color(0xFF7B8794),
                    fontSize: 14,
                  ),

                  filled: true,

                  fillColor:
                      const Color(0xFFF1F4F7),

                  prefixIcon:
                      const Padding(
                    padding:
                        EdgeInsets.only(
                      left: 14,
                      right: 8,
                      top: 15,
                    ),

                    child: Icon(
                      Icons
                          .description_outlined,
                      color:
                          Color(0xFF087F8C),
                    ),
                  ),

                  prefixIconConstraints:
                      const BoxConstraints(
                    minWidth: 48,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // PHOTO
              // ==================================================

              const Text(
                'Photo Evidence (Optional)',
                style: TextStyle(
                  color:
                      Color(0xFF102A43),
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 9),

              _buildPhotoSection(),

              const SizedBox(height: 22),

              // ==================================================
              // LOCATION
              // ==================================================

              const Text(
                'Report Location',
                style: TextStyle(
                  color:
                      Color(0xFF102A43),
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Use your current position or select the blocked road location on the map.',
                style: TextStyle(
                  color:
                      Color(0xFF7B8794),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 9),

              _buildLocationCard(),

              const SizedBox(height: 28),

              // ==================================================
              // SUBMIT
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 58,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      _isSubmitting
                          ? null
                          : _submitReport,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF087F8C,
                    ),

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        const Color(
                      0xFF75AEB4,
                    ),

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        17,
                      ),
                    ),
                  ),

                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons
                              .send_rounded,
                        ),

                  label: Text(
                    _isSubmitting
                        ? 'SUBMITTING...'
                        : 'SUBMIT BLOCKED ROAD REPORT',
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing:
                          0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// LOCATION PICKER DIALOG
// ==================================================================

class _LocationPickerDialog
    extends StatefulWidget {
  final LatLng initialLocation;

  const _LocationPickerDialog({
    required this.initialLocation,
  });

  @override
  State<_LocationPickerDialog> createState() =>
      _LocationPickerDialogState();
}

class _LocationPickerDialogState
    extends State<_LocationPickerDialog> {
  late final MapController _mapController;

  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();

    _mapController =
        MapController();

    _selectedLocation =
        widget.initialLocation;
  }

  // ============================================================
  // SELECT LOCATION
  // ============================================================

  void _selectLocation(
    LatLng location,
  ) {
    setState(() {
      _selectedLocation = location;
    });
  }

  // ============================================================
  // MOVE MAP TO CURRENT LOCATION
  // ============================================================

  Future<void>
      _moveToCurrentLocation() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Please enable location services.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _showMessage(
          'Location permission denied.',
        );
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      final LatLng location =
          LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selectedLocation =
            location;
      });

      try {
        _mapController.move(
          location,
          16,
        );
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to get your current location.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      insetPadding:
          const EdgeInsets.all(12),

      backgroundColor:
          Colors.white,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child: SizedBox(
        height:
            MediaQuery.of(context)
                    .size
                    .height *
                0.82,

        child: Column(
          children: [
            // ====================================================
            // HEADER
            // ====================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                14,
                10,
                10,
              ),

              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,

                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFEAF7F8),
                      shape:
                          BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons
                          .location_on_rounded,
                      color:
                          Color(0xFF087F8C),
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          'Pin Report Location',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF102A43,
                            ),
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          'Tap anywhere on the map to place the report pin.',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF7B8794,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    icon: const Icon(
                      Icons
                          .close_rounded,
                      color:
                          Color(
                        0xFF64748B,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // MAP
            // ====================================================

            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                child: Stack(
                  children: [
                    FlutterMap(
                      mapController:
                          _mapController,

                      options:
                          MapOptions(
                        initialCenter:
                            widget
                                .initialLocation,

                        initialZoom:
                            15,

                        minZoom: 2,

                        maxZoom: 19,

                        onTap: (
                          tapPosition,
                          point,
                        ) {
                          _selectLocation(
                            point,
                          );
                        },
                      ),

                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                          userAgentPackageName:
                              'com.resqnet.app',
                        ),

                        MarkerLayer(
                          markers: [
                            Marker(
                              point:
                                  _selectedLocation,

                              width: 58,

                              height: 70,

                              child:
                                  const Column(
                                children: [
                                  Icon(
                                    Icons
                                        .location_on_rounded,
                                    color:
                                        Color(
                                      0xFF7027A0,
                                    ),
                                    size: 52,
                                  ),

                                  SizedBox(
                                    height:
                                        1,
                                  ),
                                ],
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

                    // ==================================================
                    // MAP INSTRUCTION
                    // ==================================================

                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,

                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white
                                  .withValues(
                            alpha: 0.95,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withValues(
                                alpha: 0.12,
                              ),
                              blurRadius:
                                  10,
                            ),
                          ],
                        ),

                        child: const Row(
                          children: [
                            Icon(
                              Icons
                                  .touch_app_rounded,
                              color:
                                  Color(
                                0xFF087F8C,
                              ),
                              size: 20,
                            ),

                            SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child: Text(
                                'Tap the blocked road location on the map.',
                                style:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFF102A43,
                                  ),
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================================================
                    // CURRENT LOCATION BUTTON
                    // ==================================================

                    Positioned(
                      right: 12,
                      bottom: 75,

                      child: Material(
                        color:
                            Colors.white,

                        elevation: 4,

                        borderRadius:
                            BorderRadius
                                .circular(
                          13,
                        ),

                        child:
                            InkWell(
                          onTap:
                              _moveToCurrentLocation,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            13,
                          ),

                          child:
                              const SizedBox(
                            width: 48,
                            height: 48,

                            child: Icon(
                              Icons
                                  .my_location_rounded,
                              color:
                                  Color(
                                0xFF087F8C,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // ZOOM CONTROLS
                    // ==================================================

                    Positioned(
                      right: 12,
                      bottom: 12,

                      child: Container(
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            13,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withValues(
                                alpha: 0.15,
                              ),
                              blurRadius:
                                  8,
                            ),
                          ],
                        ),

                        child: Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                try {
                                  _mapController
                                      .move(
                                    _mapController
                                        .camera
                                        .center,

                                    _mapController
                                            .camera
                                            .zoom +
                                        1,
                                  );
                                } catch (_) {}
                              },

                              icon:
                                  const Icon(
                                Icons
                                    .add_rounded,
                              ),

                              color:
                                  const Color(
                                0xFF102A43,
                              ),
                            ),

                            Container(
                              width: 30,
                              height: 1,
                              color:
                                  const Color(
                                0xFFE1E7EC,
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                try {
                                  _mapController
                                      .move(
                                    _mapController
                                        .camera
                                        .center,

                                    _mapController
                                            .camera
                                            .zoom -
                                        1,
                                  );
                                } catch (_) {}
                              },

                              icon:
                                  const Icon(
                                Icons
                                    .remove_rounded,
                              ),

                              color:
                                  const Color(
                                0xFF102A43,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====================================================
            // SELECTED COORDINATES
            // ====================================================

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                18,
                12,
                18,
                8,
              ),

              child: Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF5F7FA,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .location_on_rounded,
                      color:
                          Color(
                        0xFF087F8C,
                      ),
                      size: 19,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}   '
                        'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',

                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFF64748B,
                          ),
                          fontSize: 10,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====================================================
            // CONFIRM BUTTON
            // ====================================================

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                18,
                5,
                18,
                18,
              ),

              child: SizedBox(
                width:
                    double.infinity,

                height: 52,

                child:
                    ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _selectedLocation,
                    );
                  },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF087F8C,
                    ),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),

                  icon: const Icon(
                    Icons
                        .check_circle_rounded,
                    size: 21,
                  ),

                  label: const Text(
                    'CONFIRM LOCATION',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}