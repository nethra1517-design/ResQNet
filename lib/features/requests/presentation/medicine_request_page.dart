import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resqnet/core/services/offline_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/widgets/location_picker.dart';

class MedicineRequestPage extends StatefulWidget {
  const MedicineRequestPage({super.key});

  @override
  State<MedicineRequestPage> createState() =>
      _MedicineRequestPageState();
}

class _MedicineRequestPageState
    extends State<MedicineRequestPage> {
  final _firestore =
      FirebaseFirestore.instance;

  final _auth =
      FirebaseAuth.instance;

  final _medicineController =
      TextEditingController();

  final _conditionController =
      TextEditingController();

  final _detailsController =
      TextEditingController();

  double? _latitude;
  double? _longitude;

  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _medicineController.dispose();
    _conditionController.dispose();
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

  Future<void> _pickLocationOnMap() async {
    final location = await showLocationPicker(
      context,
      latitude: _latitude,
      longitude: _longitude,
    );

    if (location == null || !mounted) return;

    setState(() {
      _latitude = location.latitude;
      _longitude = location.longitude;
    });

    _showMessage('Location selected from map.');
  }

  // ============================================================
  // SUBMIT MEDICINE REQUEST
  // ============================================================

  Future<void> _submitMedicineRequest() async {
    final medicine =
        _medicineController.text.trim();

    final condition =
        _conditionController.text.trim();

    final details =
        _detailsController.text.trim();

    if (medicine.isEmpty) {
      _showMessage(
        'Please enter the medicine required.',
      );
      return;
    }

    if (condition.isEmpty) {
      _showMessage(
        'Please enter the medical condition.',
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final synced = await OfflineSyncService.instance.saveAndSync(
        collectionName: 'medicine_requests',
        data: {
        // ------------------------------------------------------
        // CITIZEN
        // ------------------------------------------------------

        'citizenId':
            user.uid,

        'citizenEmail':
            user.email ?? '',

        // ------------------------------------------------------
        // MEDICINE DETAILS
        // ------------------------------------------------------

        'medicine':
            medicine,

        'condition':
            condition,

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
        // REQUEST STATUS
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
            ? 'Medicine request submitted successfully.'
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
          'Unable to submit medicine request.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to submit medicine request. Please try again.',
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
  // LOCATION
  // ============================================================

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF087F8C),
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _latitude == null || _longitude == null
                      ? 'Location not captured'
                      : 'Location selected\n'
                          'Lat: ${_latitude!.toStringAsFixed(6)}\n'
                          'Lng: ${_longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isGettingLocation ? null : _getCurrentLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: const Text('GET LOCATION'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickLocationOnMap,
                  icon: const Icon(Icons.pin_drop_rounded),
                  label: const Text('PIN ON MAP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087F8C),
                    foregroundColor: Colors.white,
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
          'Medicine Request',
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
                            .medication_rounded,
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
                            'Medicine Assistance',
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
                            'Request medicine support by providing the medicine and medical condition.',
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
                    // MEDICINE
                    // ==================================================

                    _buildLabel(
                      'Medicine Required',
                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    TextField(
                      controller:
                          _medicineController,

                      textCapitalization:
                          TextCapitalization
                              .sentences,

                      decoration:
                          _inputDecoration(
                        hint:
                            'Enter medicine name',
                        icon:
                            Icons
                                .medication_outlined,
                      ),
                    ),

                    const SizedBox(
                      height:
                          20,
                    ),

                    // ==================================================
                    // CONDITION
                    // ==================================================

                    _buildLabel(
                      'Medical Condition',
                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    TextField(
                      controller:
                          _conditionController,

                      textCapitalization:
                          TextCapitalization
                              .sentences,

                      decoration:
                          _inputDecoration(
                        hint:
                            'Enter condition or illness',
                        icon:
                            Icons
                                .healing_outlined,
                      ),
                    ),

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
                            'Mention dosage, prescription details or other requirements...',
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
                                : _submitMedicineRequest,

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
                              : 'SUBMIT MEDICINE REQUEST',

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