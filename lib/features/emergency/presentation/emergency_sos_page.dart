import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/priority_prediction_service.dart';

class EmergencySosPage extends StatefulWidget {
  const EmergencySosPage({super.key});

  @override
  State<EmergencySosPage> createState() =>
      _EmergencySosPageState();
}

class _EmergencySosPageState
    extends State<EmergencySosPage> {
  final _descriptionController =
      TextEditingController();

  final _firestore =
      FirebaseFirestore.instance;

  final _auth =
      FirebaseAuth.instance;

  final _storage =
      FirebaseStorage.instance;

  final ImagePicker _imagePicker =
      ImagePicker();

  String _emergencyType =
      'Select emergency type';

  String _severity = 'High';

  // ============================================================
  // WHO IS AFFECTED?
  // ============================================================

  String _affectedPersonType = 'None';

  int? _selectedFamilyMemberIndex;

  // ============================================================
  // CITIZEN VULNERABILITY INFORMATION
  // ============================================================

  int? _citizenAge;

  String _citizenHealthCondition = '';

  String _citizenPregnancyStatus =
      'Not Applicable';

  // ============================================================
  // FAMILY MEMBERS
  // ============================================================

  List<Map<String, dynamic>> _familyMembers = [];

  // ============================================================
  // LOCATION
  // ============================================================

  double? _latitude;

  double? _longitude;

  // ============================================================
  // PHOTO
  // ============================================================

  XFile? _selectedPhoto;

  Uint8List? _photoBytes;

  bool _isPickingPhoto = false;

  // ============================================================
  // LOADING STATES
  // ============================================================

  bool _isGettingLocation = false;

  bool _isSending = false;

  bool _isLoadingProfile = true;

  // ============================================================
  // DROPDOWN VALUES
  // ============================================================

  final List<String> _emergencyTypes = [
    'Select emergency type',
    'Fire',
    'Medical Emergency',
    'Accident',
    'Trapped Person',
    'Natural Disaster',
    'Other',
  ];

  final List<String> _severityLevels = [
    'Normal',
    'High',
    'Critical',
  ];

  final List<String> _affectedPersonTypes = [
    'None',
    'Myself',
    'Family Member',
    'Entire Family',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadCitizenProfile();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD CITIZEN PROFILE
  // ============================================================

  Future<void> _loadCitizenProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }

      return;
    }

    try {
      final document =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      if (document.exists) {
        final data =
            document.data() ?? {};

        _citizenAge =
            data['age'];

        _citizenHealthCondition =
            data['healthCondition']
                    ?.toString() ??
                '';

        _citizenPregnancyStatus =
            data['pregnancyStatus']
                    ?.toString() ??
                'Not Applicable';

        final savedFamilyMembers =
            data['familyMembers'];

        if (savedFamilyMembers is List) {
          _familyMembers =
              savedFamilyMembers
                  .whereType<Map>()
                  .map(
                    (member) =>
                        Map<String, dynamic>.from(
                      member,
                    ),
                  )
                  .toList();
        }
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to load profile information.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
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
          await Geolocator
              .isLocationServiceEnabled();

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
          await Geolocator
              .getCurrentPosition();

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
  // PHOTO SOURCE SELECTION
  // ============================================================

  Future<void> _choosePhotoSource() async {
    if (_isPickingPhoto) {
      return;
    }

    final source =
        await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFD0D5DA),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Add Emergency Photo',
                  style: TextStyle(
                    color:
                        Color(0xFF102A43),
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 16),

                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color: const Color(
                        0xFFE0F2F1,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .camera_alt_rounded,
                      color:
                          Color(0xFF087F8C),
                    ),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Use the camera',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      ImageSource.camera,
                    );
                  },
                ),

                const SizedBox(height: 5),

                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color: const Color(
                        0xFFEFF6FF,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .photo_library_rounded,
                      color:
                          Color(0xFF2563EB),
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Select an existing photo',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      ImageSource.gallery,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    await _pickPhoto(source);
  }

  // ============================================================
  // PICK PHOTO
  // ============================================================

  Future<void> _pickPhoto(
    ImageSource source,
  ) async {
    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final photo =
          await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (photo == null) {
        return;
      }

      final bytes =
          await photo.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedPhoto = photo;
        _photoBytes = bytes;
      });

      _showMessage(
        'Photo attached successfully.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to select the photo.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  // ============================================================
  // REMOVE PHOTO
  // ============================================================

  void _removePhoto() {
    setState(() {
      _selectedPhoto = null;
      _photoBytes = null;
    });

    _showMessage(
      'Photo removed.',
    );
  }

  // ============================================================
  // UPLOAD PHOTO TO FIREBASE STORAGE
  // ============================================================

  Future<String?> _uploadPhoto(
    String sosId,
  ) async {
    if (_selectedPhoto == null ||
        _photoBytes == null) {
      return null;
    }

    try {
      final user = _auth.currentUser;

      if (user == null) {
        return null;
      }

      final extension =
          _selectedPhoto!.name
              .split('.')
              .last
              .toLowerCase();

      final fileName =
          'evidence_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final storagePath =
          'emergency_sos/${user.uid}/$sosId/$fileName';

      final storageReference =
          _storage.ref().child(
                storagePath,
              );

      final metadata =
          SettableMetadata(
        contentType:
            _getContentType(extension),
      );

      await storageReference.putData(
        _photoBytes!,
        metadata,
      );

      final downloadUrl =
          await storageReference
              .getDownloadURL();

      return downloadUrl;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CONTENT TYPE
  // ============================================================

  String _getContentType(
    String extension,
  ) {
    switch (extension) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'heic':
        return 'image/heic';

      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  // ============================================================
  // DETERMINE RESPONSE DEPARTMENT
  // ============================================================

  String _getAssignedDepartment() {
    switch (_emergencyType) {
      case 'Fire':
      case 'Accident':
      case 'Trapped Person':
        return 'Fire Department';

      case 'Medical Emergency':
        return 'Health Services';

      case 'Natural Disaster':
        return 'Disaster Management';

      case 'Other':
        return 'Government Control Room';

      default:
        return 'Government Control Room';
    }
  }

  // ============================================================
  // BUILD AFFECTED PERSON SNAPSHOT
  // ============================================================

  Map<String, dynamic>
      _buildAffectedPersonData() {
    // ----------------------------------------------------------
    // NONE
    // ----------------------------------------------------------

    if (_affectedPersonType ==
        'None') {
      return {
        'type': 'none',
        'name': null,
        'relationship': null,
        'age': null,
        'healthCondition': null,
        'pregnancyStatus': null,
      };
    }

    // ----------------------------------------------------------
    // MYSELF
    // ----------------------------------------------------------

    if (_affectedPersonType ==
        'Myself') {
      return {
        'type': 'citizen',
        'name':
            'Registered Citizen',
        'relationship': 'Self',
        'age': _citizenAge,
        'healthCondition':
            _citizenHealthCondition,
        'pregnancyStatus':
            _citizenPregnancyStatus,
      };
    }

    // ----------------------------------------------------------
    // FAMILY MEMBER
    // ----------------------------------------------------------

    if (_affectedPersonType ==
        'Family Member') {
      if (_selectedFamilyMemberIndex ==
              null ||
          _selectedFamilyMemberIndex! >=
              _familyMembers.length) {
        return {};
      }

      final member =
          _familyMembers[
              _selectedFamilyMemberIndex!];

      return {
        'type': 'family_member',
        'name': member['name'],
        'relationship':
            member['relationship'],
        'age': member['age'],
        'healthCondition':
            member['healthCondition'],
        'pregnancyStatus':
            member['pregnancyStatus'],
      };
    }

    // ----------------------------------------------------------
    // ENTIRE FAMILY
    // ----------------------------------------------------------

    if (_affectedPersonType ==
        'Entire Family') {
      return {
        'type': 'entire_family',
        'name': null,
        'relationship': 'Family',
        'age': null,
        'healthCondition': null,
        'pregnancyStatus': null,
        'familyMembers':
            _familyMembers,
      };
    }

    return {
      'type': 'none',
    };
  }

  // ============================================================
  // VALIDATE AFFECTED PERSON
  // ============================================================

  bool _validateAffectedPerson() {
    if (_affectedPersonType ==
            'Family Member' &&
        _familyMembers.isEmpty) {
      _showMessage(
        'No family members are available. '
        'Add a family member in your profile first.',
      );

      return false;
    }

    if (_affectedPersonType ==
            'Family Member' &&
        _selectedFamilyMemberIndex ==
            null) {
      _showMessage(
        'Please select the affected family member.',
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // SEND SOS TO FIRESTORE
  // ============================================================

  Future<void> _sendSos() async {
    if (_emergencyType ==
        'Select emergency type') {
      _showMessage(
        'Please select an emergency type.',
      );

      return;
    }

    if (_descriptionController
        .text
        .trim()
        .isEmpty) {
      _showMessage(
        'Please describe the emergency.',
      );

      return;
    }

    if (!_validateAffectedPerson()) {
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

    final affectedPerson =
        _buildAffectedPersonData();

    if (affectedPerson.isEmpty) {
      _showMessage(
        'Please select the affected person.',
      );

      return;
    }

    // ==========================================================
    // PRIORITY PREDICTION
    // ==========================================================

    int? priorityAge;

    String priorityHealth = '';

    String priorityPregnancy =
        'Not Applicable';

    if (_affectedPersonType ==
        'Myself') {
      priorityAge = _citizenAge;

      priorityHealth =
          _citizenHealthCondition;

      priorityPregnancy =
          _citizenPregnancyStatus;
    }

    if (_affectedPersonType ==
        'Family Member') {
      priorityAge =
          affectedPerson['age'];

      priorityHealth =
          affectedPerson[
                    'healthCondition']
                ?.toString() ??
              '';

      priorityPregnancy =
          affectedPerson[
                    'pregnancyStatus']
                ?.toString() ??
              'Not Applicable';
    }

    final priorityResult =
        PriorityPredictionService
            .calculate(
      emergencySeverity:
          _severity,
      affectedPersonType:
          _affectedPersonType,
      age: priorityAge,
      healthCondition:
          priorityHealth,
      pregnancyStatus:
          priorityPregnancy,
      familyMembers:
          _familyMembers,
    );

    setState(() {
      _isSending = true;
    });

    try {
      final assignedDepartment =
          _getAssignedDepartment();

      // ========================================================
      // CREATE SOS DOCUMENT FIRST
      // ========================================================

      final sosReference =
          await _firestore
              .collection('emergency_sos')
              .add({
        'citizenId': user.uid,

        'citizenEmail':
            user.email ?? '',

        'emergencyType':
            _emergencyType,

        'description':
            _descriptionController
                .text
                .trim(),

        'latitude':
            _latitude,

        'longitude':
            _longitude,

        'severity':
            _severity,

        // ------------------------------------------------------
        // AFFECTED PERSON
        // ------------------------------------------------------

        'affectedPersonType':
            _affectedPersonType,

        'affectedPerson':
            affectedPerson,

        // ------------------------------------------------------
        // PRIORITY
        // ------------------------------------------------------

        'priority': {
          'level':
              priorityResult.level,
          'score':
              priorityResult.score,
          'reasons':
              priorityResult.reasons,
        },

        // ------------------------------------------------------
        // PHOTO
        // ------------------------------------------------------

        'photoUrl': null,

        'photoAttached':
            _selectedPhoto != null,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status':
            'received',

        'assignedDepartment':
            assignedDepartment,

        'assignedUnit':
            null,

        // ------------------------------------------------------
        // TIMESTAMP
        // ------------------------------------------------------

        'createdAt':
            FieldValue
                .serverTimestamp(),

        'updatedAt':
            FieldValue
                .serverTimestamp(),
      });

      // ========================================================
      // UPLOAD OPTIONAL PHOTO
      // ========================================================

      if (_selectedPhoto != null &&
          _photoBytes != null) {
        final photoUrl =
            await _uploadPhoto(
          sosReference.id,
        );

        if (photoUrl == null) {
          // Remove the SOS document if the
          // citizen selected a photo but the
          // evidence upload failed.
          await sosReference.delete();

          throw Exception(
            'PHOTO_UPLOAD_FAILED',
          );
        }

        await sosReference.update({
          'photoUrl': photoUrl,
          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        });
      }

      if (!mounted) return;

      _showMessage(
        'Emergency SOS sent successfully.',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 800,
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      if (e.code ==
          'permission-denied') {
        _showMessage(
          'Permission denied. Please check Firebase rules.',
        );
      } else {
        _showMessage(
          'Unable to send SOS. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains(
            'PHOTO_UPLOAD_FAILED',
          )) {
        _showMessage(
          'SOS was not submitted because the photo could not be uploaded.',
        );
      } else {
        _showMessage(
          'Unable to send SOS. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
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
        content: Text(message),
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
      hintText: hint,

      prefixIcon: Icon(
        icon,
        color:
            const Color(0xFF087F8C),
      ),

      filled: true,

      fillColor:
          const Color(0xFFF5F7FA),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide.none,
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
      style: const TextStyle(
        fontWeight:
            FontWeight.w700,
        color:
            Color(0xFF102A43),
      ),
    );
  }

  // ============================================================
  // PHOTO SECTION
  // ============================================================

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildLabel(
          'Photo Evidence (Optional)',
        ),

        const SizedBox(height: 8),

        if (_photoBytes == null)
          InkWell(
            borderRadius:
                BorderRadius.circular(14),
            onTap:
                _isPickingPhoto
                    ? null
                    : _choosePhotoSource,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFF5F7FA),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color:
                      const Color(0xFFDCE3E8),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(0xFFE0F2F1),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: _isPickingPhoto
                        ? const Padding(
                            padding:
                                EdgeInsets.all(
                              12,
                            ),
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Color(0xFF087F8C),
                            ),
                          )
                        : const Icon(
                            Icons
                                .add_a_photo_rounded,
                            color:
                                Color(0xFF087F8C),
                          ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color:
                                Color(0xFF102A43),
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          'Capture or select evidence of the emergency.',
                          style: TextStyle(
                            color:
                                Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                        Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color:
                    const Color(0xFFDCE3E8),
              ),
            ),
            clipBehavior:
                Clip.antiAlias,
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width:
                          double.infinity,
                      height: 210,
                      child: Image.memory(
                        _photoBytes!,
                        fit:
                            BoxFit.cover,
                      ),
                    ),

                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.black
                            .withValues(
                          alpha: 0.55,
                        ),
                        shape:
                            const CircleBorder(),
                        child: InkWell(
                          customBorder:
                              const CircleBorder(),
                          onTap:
                              _removePhoto,
                          child:
                              const Padding(
                            padding:
                                EdgeInsets.all(
                              8,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color:
                                  Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .check_circle_rounded,
                        color:
                            Color(0xFF16A34A),
                        size: 20,
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      const Expanded(
                        child: Text(
                          'Photo attached',
                          style:
                              TextStyle(
                            color:
                                Color(0xFF166534),
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed:
                            _choosePhotoSource,
                        child:
                            const Text(
                          'Change',
                          style:
                              TextStyle(
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
          ),
      ],
    );
  }

  // ============================================================
  // FAMILY MEMBER SELECTOR
  // ============================================================

  Widget _buildFamilyMemberSelector() {
    if (_affectedPersonType !=
        'Family Member') {
      return const SizedBox.shrink();
    }

    if (_familyMembers.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(15),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFFFF7ED),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color:
                const Color(0xFFFED7AA),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons
                  .info_outline_rounded,
              color:
                  Color(0xFFEA580C),
            ),

            SizedBox(width: 10),

            Expanded(
              child: Text(
                'No family members found. '
                'Add family members from My Profile.',
                style: TextStyle(
                  color:
                      Color(0xFF9A3412),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 18,
        ),

        _buildLabel(
          'Select Family Member',
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<int>(
          initialValue:
              _selectedFamilyMemberIndex,

          decoration:
              _inputDecoration(
            hint:
                'Select affected family member',
            icon: Icons
                .person_search_outlined,
          ),

          items: _familyMembers
              .asMap()
              .entries
              .map(
            (entry) {
              final index =
                  entry.key;

              final member =
                  entry.value;

              final name =
                  member['name']
                          ?.toString() ??
                      'Unnamed';

              final relationship =
                  member['relationship']
                          ?.toString() ??
                      '';

              final age =
                  member['age']
                          ?.toString() ??
                      '';

              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  '$name'
                  '${relationship.isNotEmpty ? ' ($relationship)' : ''}'
                  '${age.isNotEmpty ? ' - $age yrs' : ''}',
                ),
              );
            },
          ).toList(),

          onChanged: (value) {
            setState(() {
              _selectedFamilyMemberIndex =
                  value;
            });
          },
        ),
      ],
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

    const red =
        Color(0xFFEF4444);

    const background =
        Color(0xFFF7F9FB);

    return Scaffold(
      backgroundColor:
          background,

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        elevation: 0,

        foregroundColor:
            navy,

        title: const Text(
          'Emergency SOS',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: _isLoadingProfile
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SafeArea(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  20,
                  14,
                  20,
                  30,
                ),

                child: Column(
                  children: [
                    // ==================================================
                    // EMERGENCY HEADER
                    // ==================================================

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFEEEE,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFFFD1D1,
                          ),
                        ),
                      ),

                      child:
                          const Row(
                        children: [
                          Icon(
                            Icons
                                .warning_rounded,
                            color:
                                red,
                            size: 30,
                          ),

                          SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Emergency Assistance',
                                  style:
                                      TextStyle(
                                    color:
                                        navy,
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                  ),
                                ),

                                SizedBox(
                                  height: 2,
                                ),

                                Text(
                                  'Provide details for appropriate response.',
                                  style:
                                      TextStyle(
                                    color:
                                        Color(
                                      0xFF64748B,
                                    ),
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // FORM
                    // ==================================================

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .all(20),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          22,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
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
                          // EMERGENCY TYPE
                          // ==================================================

                          _buildLabel(
                            'Emergency Type',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          DropdownButtonFormField<
                              String>(
                            initialValue:
                                _emergencyType,

                            decoration:
                                _inputDecoration(
                              hint:
                                  'Select emergency type',
                              icon: Icons
                                  .emergency_outlined,
                            ),

                            items:
                                _emergencyTypes
                                    .map(
                              (type) {
                                return DropdownMenuItem<
                                    String>(
                                  value:
                                      type,
                                  child:
                                      Text(
                                    type,
                                  ),
                                );
                              },
                            ).toList(),

                            onChanged:
                                (value) {
                              if (value !=
                                  null) {
                                setState(
                                  () {
                                    _emergencyType =
                                        value;
                                  },
                                );
                              }
                            },
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // ==================================================
                          // DESCRIPTION
                          // ==================================================

                          _buildLabel(
                            'Emergency Description',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          TextField(
                            controller:
                                _descriptionController,

                            maxLines: 5,

                            decoration:
                                _inputDecoration(
                              hint:
                                  'Describe what is happening...',
                              icon: Icons
                                  .description_outlined,
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // ==================================================
                          // WHO IS AFFECTED
                          // ==================================================

                          _buildLabel(
                            'Who is affected?',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          DropdownButtonFormField<
                              String>(
                            initialValue:
                                _affectedPersonType,

                            decoration:
                                _inputDecoration(
                              hint:
                                  'Select who is affected',
                              icon: Icons
                                  .people_alt_outlined,
                            ),

                            items:
                                _affectedPersonTypes
                                    .map(
                              (type) {
                                return DropdownMenuItem<
                                    String>(
                                  value:
                                      type,
                                  child:
                                      Text(
                                    type,
                                  ),
                                );
                              },
                            ).toList(),

                            onChanged:
                                (value) {
                              if (value !=
                                  null) {
                                setState(
                                  () {
                                    _affectedPersonType =
                                        value;

                                    _selectedFamilyMemberIndex =
                                        null;
                                  },
                                );
                              }
                            },
                          ),

                          // FAMILY MEMBER
                          _buildFamilyMemberSelector(),

                          const SizedBox(
                            height: 20,
                          ),

                          // ==================================================
                          // OPTIONAL PHOTO
                          // ==================================================

                          _buildPhotoSection(),

                          const SizedBox(
                            height: 20,
                          ),

                          // ==================================================
                          // LOCATION
                          // ==================================================

                          _buildLabel(
                            'Current Location',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Container(
                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets
                                    .all(
                              16,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFF5F7FA,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),

                            child: Row(
                              children: [
                                const Icon(
                                  Icons
                                      .location_on_rounded,
                                  color:
                                      teal,
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child:
                                      Text(
                                    _latitude ==
                                                null ||
                                            _longitude ==
                                                null
                                        ? 'Location not captured'
                                        : 'Location captured\n'
                                            'Lat: ${_latitude!.toStringAsFixed(6)}\n'
                                            'Lng: ${_longitude!.toStringAsFixed(6)}',
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(
                                        0xFF64748B,
                                      ),
                                      fontSize:
                                          13,
                                      height:
                                          1.4,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 8,
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
                                                    FontWeight
                                                        .w800,
                                              ),
                                            ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // ==================================================
                          // SEVERITY
                          // ==================================================

                          _buildLabel(
                            'Severity',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          DropdownButtonFormField<
                              String>(
                            initialValue:
                                _severity,

                            decoration:
                                _inputDecoration(
                              hint:
                                  'Select severity',
                              icon: Icons
                                  .priority_high_rounded,
                            ),

                            items:
                                _severityLevels
                                    .map(
                              (level) {
                                return DropdownMenuItem<
                                    String>(
                                  value:
                                      level,
                                  child:
                                      Text(
                                    level,
                                  ),
                                );
                              },
                            ).toList(),

                            onChanged:
                                (value) {
                              if (value !=
                                  null) {
                                setState(
                                  () {
                                    _severity =
                                        value;
                                  },
                                );
                              }
                            },
                          ),

                          const SizedBox(
                            height: 28,
                          ),

                          // ==================================================
                          // SEND SOS
                          // ==================================================

                          SizedBox(
                            width:
                                double.infinity,

                            height: 56,

                            child:
                                ElevatedButton
                                    .icon(
                              onPressed:
                                  _isSending
                                      ? null
                                      : _sendSos,

                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    red,

                                foregroundColor:
                                    Colors.white,

                                disabledBackgroundColor:
                                    Colors
                                        .grey,

                                elevation: 0,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    16,
                                  ),
                                ),
                              ),

                              icon: _isSending
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
                                          .notifications_active_rounded,
                                    ),

                              label:
                                  Text(
                                _isSending
                                    ? 'SENDING SOS...'
                                    : 'SEND EMERGENCY SOS',

                                style:
                                    const TextStyle(
                                  fontSize:
                                      15,
                                  fontWeight:
                                      FontWeight
                                          .w900,
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