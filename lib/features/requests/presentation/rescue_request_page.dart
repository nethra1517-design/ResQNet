import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resqnet/core/services/offline_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class RescueRequestPage extends StatefulWidget {
  const RescueRequestPage({super.key});

  @override
  State<RescueRequestPage> createState() =>
      _RescueRequestPageState();
}

class _RescueRequestPageState
    extends State<RescueRequestPage> {
  final _firestore =
      FirebaseFirestore.instance;

  final _auth =
      FirebaseAuth.instance;

  final _detailsController =
      TextEditingController();

  String? _selectedRescueType;

  double? _latitude;
  double? _longitude;

  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  final List<String> _rescueTypes = [
    'Boat Rescue',
    'Medical Evacuation',
    'Vehicle Rescue',
    'Search and Rescue',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final serviceEnabled =
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

        if (permission ==
            LocationPermission.denied) {
          _showMessage(
            'Location permission was denied.',
          );
          return;
        }
      }

      if (permission ==
          LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. '
          'Enable it from app settings.',
        );
        return;
      }

      final position =
          await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _latitude =
            position.latitude;

        _longitude =
            position.longitude;
      });

      _showMessage(
        'Location captured successfully.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to get your current location.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // SUBMIT RESCUE REQUEST
  // ============================================================

  Future<void> _submitRescueRequest() async {
    if (_selectedRescueType == null) {
      _showMessage(
        'Please select the type of rescue needed.',
      );
      return;
    }

    if (_latitude == null ||
        _longitude == null) {
      _showMessage(
        'Please capture your current location.',
      );
      return;
    }

    final user =
        _auth.currentUser;

    if (user == null) {
      _showMessage(
        'You are not logged in. Please sign in again.',
      );
      return;
    }

    final details =
        _detailsController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final synced = await OfflineSyncService.instance.saveAndSync(
        collectionName: 'rescue_requests',
        data: {
        // ------------------------------------------------------
        // CITIZEN
        // ------------------------------------------------------

        'citizenId':
            user.uid,

        'citizenEmail':
            user.email ?? '',

        // ------------------------------------------------------
        // RESCUE DETAILS
        // ------------------------------------------------------

        'rescueType':
            _selectedRescueType,

        'details':
            details,

        // ------------------------------------------------------
        // LOCATION
        // ------------------------------------------------------

        'latitude':
            _latitude,

        'longitude':
            _longitude,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status':
            'received',

        'assignedOrganization':
            null,

        'assignedUnit':
            null,

        // ------------------------------------------------------
        // TIMESTAMPS
        // ------------------------------------------------------

        'createdAt':
            DateTime.now().toIso8601String(),

        'updatedAt':
            DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      _showMessage(
        synced
            ? 'Rescue request submitted successfully.'
            : 'Saved — Waiting for Network. It will sync automatically.',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      if (e.code ==
          'permission-denied') {
        _showMessage(
          'Permission denied. Please check Firestore rules.',
        );
      } else {
        _showMessage(
          'Unable to submit rescue request.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to submit rescue request. Please try again.',
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
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText:
          hint,

      prefixIcon:
          Icon(
        icon,
        color:
            const Color(0xFF087F8C),
      ),

      filled:
          true,

      fillColor:
          const Color(0xFFF5F7FA),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xFF087F8C),
          width:
              1.5,
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(
    String text,
  ) {
    return Text(
      text,
      style:
          const TextStyle(
        color:
            Color(0xFF102A43),
        fontSize:
            14,
        fontWeight:
            FontWeight.w800,
      ),
    );
  }

  // ============================================================
  // RESCUE TYPE DROPDOWN
  // ============================================================

Widget _buildRescueTypeDropdown() {
  return DropdownButtonFormField<String>(
    initialValue: _selectedRescueType,

    decoration: _inputDecoration(
      hint: 'Select rescue type',
      icon: Icons.directions_boat_rounded,
    ),

    items: _rescueTypes.map(
      (type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      },
    ).toList(),

    onChanged: (value) {
      setState(() {
        _selectedRescueType = value;
      });
    },
  );
}

  // ============================================================
  // LOCATION
  // ============================================================

  Widget _buildLocationSection() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF5F7FA),

        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      child:
          Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color:
                Color(0xFF087F8C),
            size:
                26,
          ),

          const SizedBox(
            width:
                12,
          ),

          Expanded(
            child:
                Text(
              _latitude == null ||
                      _longitude == null
                  ? 'Location not captured'
                  : 'Location captured\n'
                      'Lat: ${_latitude!.toStringAsFixed(6)}\n'
                      'Lng: ${_longitude!.toStringAsFixed(6)}',

              style:
                  const TextStyle(
                color:
                    Color(0xFF64748B),
                fontSize:
                    13,
                height:
                    1.4,
              ),
            ),
          ),

          const SizedBox(
            width:
                8,
          ),

          TextButton(
            onPressed:
                _isGettingLocation
                    ? null
                    : _getCurrentLocation,

            child:
                _isGettingLocation
                    ? const SizedBox(
                        width:
                            18,
                        height:
                            18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Text(
                        'GET LOCATION',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
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
  Widget build(
    BuildContext context,
  ) {
    const navy =
        Color(0xFF102A43);

    const teal =
        Color(0xFF087F8C);

    const background =
        Color(0xFFF7F9FB);

    return Scaffold(
      backgroundColor:
          background,

      appBar:
          AppBar(
        backgroundColor:
            Colors.white,

        elevation:
            0,

        foregroundColor:
            navy,

        title:
            const Text(
          'Rescue Request',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body:
          SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            30,
          ),

          child:
              Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE8F7F7,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFC5E8E8,
                    ),
                  ),
                ),

                child:
                    Row(
                  children: [
                    Container(
                      width:
                          52,
                      height:
                          52,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),

                      child:
                          const Icon(
                        Icons
                            .directions_boat_rounded,
                        color:
                            teal,
                        size:
                            30,
                      ),
                    ),

                    const SizedBox(
                      width:
                          14,
                    ),

                    const Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            'Rescue Assistance',
                            style:
                                TextStyle(
                              color:
                                  navy,
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          SizedBox(
                            height:
                                4,
                          ),

                          Text(
                            'Request rescue support by selecting the type of rescue needed and sharing your location.',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF64748B,
                              ),
                              fontSize:
                                  12,
                              height:
                                  1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:
                    16,
              ),

              // ==================================================
              // FORM CARD
              // ==================================================

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black
                              .withValues(
                        alpha:
                            0.05,
                      ),
                      blurRadius:
                          16,
                      offset:
                          const Offset(
                        0,
                        6,
                      ),
                    ),
                  ],
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    // ==================================================
                    // RESCUE TYPE
                    // ==================================================

                    _buildLabel(
                      'Type of Rescue Needed',
                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    _buildRescueTypeDropdown(),

                    const SizedBox(
                      height:
                          20,
                    ),

                    // ==================================================
                    // ADDITIONAL DETAILS
                    // ==================================================

                    _buildLabel(
                      'Additional Details (Optional)',
                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    TextField(
                      controller:
                          _detailsController,

                      maxLines:
                          4,

                      textCapitalization:
                          TextCapitalization
                              .sentences,

                      decoration:
                          _inputDecoration(
                        hint:
                            'Describe the rescue situation or any additional information...',
                        icon:
                            Icons
                                .description_outlined,
                      ),
                    ),

                    const SizedBox(
                      height:
                          20,
                    ),

                    // ==================================================
                    // LOCATION
                    // ==================================================

                    _buildLabel(
                      'Current Location',
                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    _buildLocationSection(),

                    const SizedBox(
                      height:
                          28,
                    ),

                    // ==================================================
                    // SUBMIT
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,

                      height:
                          56,

                      child:
                          ElevatedButton
                              .icon(
                        onPressed:
                            _isSubmitting
                                ? null
                                : _submitRescueRequest,

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              teal,

                          foregroundColor:
                              Colors.white,

                          disabledBackgroundColor:
                              Colors.grey,

                          elevation:
                              0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),

                        icon:
                            _isSubmitting
                                ? const SizedBox(
                                    width:
                                        20,
                                    height:
                                        20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .send_rounded,
                                  ),

                        label:
                            Text(
                          _isSubmitting
                              ? 'SUBMITTING...'
                              : 'SUBMIT RESCUE REQUEST',

                          style:
                              const TextStyle(
                            fontSize:
                                14,
                            fontWeight:
                                FontWeight.w900,
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
      ),
    );
  }
}