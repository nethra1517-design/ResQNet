import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CitizenProfilePage extends StatefulWidget {
  const CitizenProfilePage({super.key});

  @override
  State<CitizenProfilePage> createState() =>
      _CitizenProfilePageState();
}

class _CitizenProfilePageState extends State<CitizenProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _healthConditionController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isSaving = false;

  String _pregnancyStatus = 'Not Applicable';

  final List<String> _pregnancyStatuses = [
    'Not Applicable',
    'Pregnant',
    'Not Pregnant',
  ];

  final List<_FamilyMemberData> _familyMembers = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _healthConditionController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _emergencyContactController.dispose();

    for (final member in _familyMembers) {
      member.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final document =
          await _firestore.collection('users').doc(user.uid).get();

      if (document.exists) {
        final data = document.data() ?? {};

        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _ageController.text =
            data['age']?.toString() ?? '';
        _healthConditionController.text =
            data['healthCondition'] ?? '';
        _addressController.text =
            data['address'] ?? '';
        _districtController.text =
            data['district'] ?? '';
        _stateController.text =
            data['state'] ?? '';
        _emergencyContactController.text =
            data['emergencyContact'] ?? '';

        final savedPregnancyStatus =
            data['pregnancyStatus'];

        if (savedPregnancyStatus != null &&
            _pregnancyStatuses.contains(
              savedPregnancyStatus,
            )) {
          _pregnancyStatus = savedPregnancyStatus;
        }

        // Load family members
        final savedFamilyMembers =
            data['familyMembers'];

        if (savedFamilyMembers is List) {
          for (final item in savedFamilyMembers) {
            if (item is Map) {
              final member = _FamilyMemberData();

              member.nameController.text =
                  item['name']?.toString() ?? '';

              member.relationshipController.text =
                  item['relationship']?.toString() ?? '';

              member.ageController.text =
                  item['age']?.toString() ?? '';

              member.healthController.text =
                  item['healthCondition']?.toString() ?? '';

              final savedMemberPregnancy =
                  item['pregnancyStatus']?.toString();

              if (savedMemberPregnancy != null &&
                  _pregnancyStatuses.contains(
                    savedMemberPregnancy,
                  )) {
                member.pregnancyStatus =
                    savedMemberPregnancy;
              }

              _familyMembers.add(member);
            }
          }
        }
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to load profile.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ADD FAMILY MEMBER
  // ============================================================

  void _addFamilyMember() {
    setState(() {
      _familyMembers.add(_FamilyMemberData());
    });
  }

  // ============================================================
  // REMOVE FAMILY MEMBER
  // ============================================================

  void _removeFamilyMember(int index) {
    final member = _familyMembers[index];

    member.dispose();

    setState(() {
      _familyMembers.removeAt(index);
    });
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please sign in again.');
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showMessage(
        'Name and phone number are required.',
      );
      return;
    }

    if (_ageController.text.trim().isEmpty) {
      _showMessage('Please enter your age.');
      return;
    }

    final age = int.tryParse(
      _ageController.text.trim(),
    );

    if (age == null || age <= 0 || age > 120) {
      _showMessage('Please enter a valid age.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final familyMembers = _familyMembers.map((member) {
        return {
          'name': member.nameController.text.trim(),
          'relationship':
              member.relationshipController.text.trim(),
          'age': int.tryParse(
                member.ageController.text.trim(),
              ) ??
              0,
          'healthCondition':
              member.healthController.text.trim(),
          'pregnancyStatus':
              member.pregnancyStatus,
        };
      }).toList();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': _nameController.text.trim(),
          'email': user.email ?? '',
          'phone': _phoneController.text.trim(),

          // Citizen vulnerability information
          'age': age,
          'healthCondition':
              _healthConditionController.text.trim(),
          'pregnancyStatus': _pregnancyStatus,

          'address': _addressController.text.trim(),
          'district': _districtController.text.trim(),
          'state': _stateController.text.trim(),
          'emergencyContact':
              _emergencyContactController.text.trim(),

          // Structured family information
          'familyMembers': familyMembers,

          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      _showMessage(
        'Profile updated successfully.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to save profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
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
        color: const Color(0xFF087F8C),
      ),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF102A43),
      ),
    );
  }

  // ============================================================
  // FAMILY MEMBER CARD
  // ============================================================

  Widget _buildFamilyMemberCard(
    int index,
    _FamilyMemberData member,
  ) {
    const teal = Color(0xFF087F8C);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family member heading
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: teal,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Family Member ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  _removeFamilyMember(index);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
                tooltip: 'Remove family member',
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Name
          _buildLabel('Name'),

          const SizedBox(height: 8),

          TextField(
            controller: member.nameController,
            textCapitalization:
                TextCapitalization.words,
            decoration: _inputDecoration(
              hint: 'Family member name',
              icon: Icons.person_outline,
            ),
          ),

          const SizedBox(height: 16),

          // Relationship
          _buildLabel('Relationship'),

          const SizedBox(height: 8),

          TextField(
            controller:
                member.relationshipController,
            textCapitalization:
                TextCapitalization.words,
            decoration: _inputDecoration(
              hint: 'e.g. Mother, Father, Sister',
              icon: Icons.people_outline,
            ),
          ),

          const SizedBox(height: 16),

          // Age
          _buildLabel('Age'),

          const SizedBox(height: 8),

          TextField(
            controller: member.ageController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              hint: 'Age',
              icon: Icons.cake_outlined,
            ),
          ),

          const SizedBox(height: 16),

          // Health
          _buildLabel('Health Condition'),

          const SizedBox(height: 8),

          TextField(
            controller: member.healthController,
            maxLines: 2,
            decoration: _inputDecoration(
              hint:
                  'e.g. No known condition, asthma, diabetes',
              icon: Icons.health_and_safety_outlined,
            ),
          ),

          const SizedBox(height: 16),

          // Pregnancy
          _buildLabel('Pregnancy Status'),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue:
                member.pregnancyStatus,
            decoration: _inputDecoration(
              hint: 'Pregnancy status',
              icon: Icons.pregnant_woman_outlined,
            ),
            items: _pregnancyStatuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  member.pregnancyStatus =
                      value;
                });
              }
            },
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
    const navy = Color(0xFF102A43);
    const teal = Color(0xFF087F8C);
    const red = Color(0xFFEF4444);
    const background = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: navy,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  32,
                ),
                child: Column(
                  children: [
                    // ==================================================
                    // PROFILE ICON
                    // ==================================================

                    const CircleAvatar(
                      radius: 42,
                      backgroundColor:
                          Color(0xFFE0F2F1),
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: teal,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Citizen Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // PROFILE CARD
                    // ==================================================

                    Container(
                      padding:
                          const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset:
                                const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // FULL NAME
                          _buildLabel('Full Name'),

                          const SizedBox(height: 8),

                          TextField(
                            controller:
                                _nameController,
                            textCapitalization:
                                TextCapitalization
                                    .words,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'Enter your full name',
                              icon:
                                  Icons.person_outline,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // EMAIL
                          _buildLabel('Email'),

                          const SizedBox(height: 8),

                          TextField(
                            controller:
                                TextEditingController(
                              text: _auth.currentUser
                                      ?.email ??
                                  '',
                            ),
                            readOnly: true,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'Email address',
                              icon:
                                  Icons.email_outlined,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // PHONE
                          _buildLabel(
                            'Phone Number',
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller:
                                _phoneController,
                            keyboardType:
                                TextInputType.phone,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'Enter your phone number',
                              icon:
                                  Icons.phone_outlined,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // AGE
                          _buildLabel('Age'),

                          const SizedBox(height: 8),

                          TextField(
                            controller:
                                _ageController,
                            keyboardType:
                                TextInputType.number,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'Enter your age',
                              icon:
                                  Icons.cake_outlined,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // HEALTH CONDITION
                          _buildLabel(
                            'Health Condition',
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller:
                                _healthConditionController,
                            maxLines: 2,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'e.g. No known condition, asthma, diabetes',
                              icon: Icons
                                  .health_and_safety_outlined,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // PREGNANCY STATUS
                          _buildLabel(
                            'Pregnancy Status',
                          ),

                          const SizedBox(height: 8),

                          DropdownButtonFormField<String>(
                            initialValue:
                                _pregnancyStatus,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'Select pregnancy status',
                              icon: Icons
                                  .pregnant_woman_outlined,
                            ),
                            items:
                                _pregnancyStatuses
                                    .map(
                              (status) {
                                return DropdownMenuItem<
                                    String>(
                                  value: status,
                                  child:
                                      Text(status),
                                );
                              },
                            ).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _pregnancyStatus =
                                      value;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 18),

                          // ADDRESS
                          _buildLabel('Address'),

                          const SizedBox(height: 8),

                          TextField(
                            controller:
                                _addressController,
                            maxLines: 2,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'Enter your address',
                              icon:
                                  Icons.home_outlined,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // DISTRICT
                          _buildLabel('District'),

                          const SizedBox(height: 8),

                          TextField(
                            controller:
                                _districtController,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'Enter your district',
                              icon: Icons
                                  .location_city_outlined,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // STATE
                          _buildLabel('State'),

                          const SizedBox(height: 8),

                          TextField(
                            controller:
                                _stateController,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'Enter your state',
                              icon:
                                  Icons.map_outlined,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // EMERGENCY CONTACT
                          _buildLabel(
                            'Emergency Contact',
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller:
                                _emergencyContactController,
                            keyboardType:
                                TextInputType.phone,
                            decoration:
                                _inputDecoration(
                              hint:
                                  'Emergency contact number',
                              icon: Icons
                                  .contact_phone_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // FAMILY MEMBERS
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset:
                                const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .family_restroom_rounded,
                                color: teal,
                                size: 27,
                              ),

                              const SizedBox(width: 10),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Family Members',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                        color: navy,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Add details of family members for emergency prioritization.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(
                                          0xFF64748B,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          if (_familyMembers.isEmpty)
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(
                                18,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: background,
                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                              ),
                              child: const Text(
                                'No family members added yet.',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  color:
                                      Color(0xFF64748B),
                                ),
                              ),
                            ),

                          const SizedBox(height: 4),

                          ..._familyMembers
                              .asMap()
                              .entries
                              .map(
                            (entry) {
                              return _buildFamilyMemberCard(
                                entry.key,
                                entry.value,
                              );
                            },
                          ),

                          // ADD FAMILY MEMBER
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _addFamilyMember,
                              style:
                                  OutlinedButton.styleFrom(
                                foregroundColor:
                                    teal,
                                side:
                                    const BorderSide(
                                  color: teal,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(14),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_rounded,
                              ),
                              label: const Text(
                                'ADD FAMILY MEMBER',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // SAVE PROFILE
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            _isSaving
                                ? null
                                : _saveProfile,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SAVE PROFILE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w800,
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

// ================================================================
// FAMILY MEMBER DATA
// ================================================================

class _FamilyMemberData {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController relationshipController =
      TextEditingController();

  final TextEditingController ageController =
      TextEditingController();

  final TextEditingController healthController =
      TextEditingController();

  String pregnancyStatus = 'Not Applicable';

  void dispose() {
    nameController.dispose();
    relationshipController.dispose();
    ageController.dispose();
    healthController.dispose();
  }
}