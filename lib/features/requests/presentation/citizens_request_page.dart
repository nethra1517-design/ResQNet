import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CitizenRequestsPage extends StatelessWidget {
  const CitizenRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in again.'),
        ),
      );
    }

    final emergencyStream = FirebaseFirestore.instance
        .collection('emergency_sos')
        .where('citizenId', isEqualTo: user.uid)
        .snapshots();

    final foodStream = FirebaseFirestore.instance
        .collection('food_requests')
        .where('citizenId', isEqualTo: user.uid)
        .snapshots();

    final medicineStream = FirebaseFirestore.instance
        .collection('medicine_requests')
        .where('citizenId', isEqualTo: user.uid)
        .snapshots();

    final rescueStream = FirebaseFirestore.instance
        .collection('rescue_requests')
        .where('citizenId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102A43),
        elevation: 0,
        title: const Text(
          'My Requests',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: emergencyStream,
        builder: (context, emergencySnapshot) {
          if (emergencySnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (emergencySnapshot.hasError) {
            return _buildErrorState();
          }

          return StreamBuilder<QuerySnapshot>(
            stream: foodStream,
            builder: (context, foodSnapshot) {
              if (foodSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (foodSnapshot.hasError) {
                return _buildErrorState();
              }

              return StreamBuilder<QuerySnapshot>(
                stream: medicineStream,
                builder: (context, medicineSnapshot) {
                  if (medicineSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (medicineSnapshot.hasError) {
                    return _buildErrorState();
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: rescueStream,
                    builder: (context, rescueSnapshot) {
                      if (rescueSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (rescueSnapshot.hasError) {
                        return _buildErrorState();
                      }

                      final List<_RequestItem> requests = [];

                      // ==================================================
                      // EMERGENCY REQUESTS
                      // ==================================================

                      final emergencyDocs =
                          emergencySnapshot.data?.docs ?? [];

                      for (final document in emergencyDocs) {
                        requests.add(
                          _RequestItem(
                            requestId: document.id,
                            type: _RequestType.emergency,
                            data: document.data()
                                as Map<String, dynamic>,
                          ),
                        );
                      }

                      // ==================================================
                      // FOOD REQUESTS
                      // ==================================================

                      final foodDocs =
                          foodSnapshot.data?.docs ?? [];

                      for (final document in foodDocs) {
                        requests.add(
                          _RequestItem(
                            requestId: document.id,
                            type: _RequestType.food,
                            data: document.data()
                                as Map<String, dynamic>,
                          ),
                        );
                      }

                      // ==================================================
                      // MEDICINE REQUESTS
                      // ==================================================

                      final medicineDocs =
                          medicineSnapshot.data?.docs ?? [];

                      for (final document in medicineDocs) {
                        requests.add(
                          _RequestItem(
                            requestId: document.id,
                            type: _RequestType.medicine,
                            data: document.data()
                                as Map<String, dynamic>,
                          ),
                        );
                      }

                      // ==================================================
                      // RESCUE REQUESTS
                      // ==================================================

                      final rescueDocs =
                          rescueSnapshot.data?.docs ?? [];

                      for (final document in rescueDocs) {
                        requests.add(
                          _RequestItem(
                            requestId: document.id,
                            type: _RequestType.rescue,
                            data: document.data()
                                as Map<String, dynamic>,
                          ),
                        );
                      }

                      // ==================================================
                      // SORT NEWEST FIRST
                      // ==================================================

                      requests.sort(
                        (a, b) {
                          final aTime =
                              a.data['createdAt'] as Timestamp?;

                          final bTime =
                              b.data['createdAt'] as Timestamp?;

                          if (aTime == null && bTime == null) {
                            return 0;
                          }

                          if (aTime == null) {
                            return 1;
                          }

                          if (bTime == null) {
                            return -1;
                          }

                          return bTime.compareTo(aTime);
                        },
                      );

                      // ==================================================
                      // EMPTY STATE
                      // ==================================================

                      if (requests.isEmpty) {
                        return _buildEmptyState();
                      }

                      // ==================================================
                      // REQUEST LIST
                      // ==================================================

                      return RefreshIndicator(
                        onRefresh: () async {
                          await Future.delayed(
                            const Duration(
                              milliseconds: 300,
                            ),
                          );
                        },

                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            18,
                            20,
                            30,
                          ),

                          children: [
                            _buildHeader(
                              requests.length,
                            ),

                            const SizedBox(height: 18),

                            ...requests.map(
                              (request) {
                                Widget card;

                                switch (request.type) {
                                  case _RequestType.emergency:
                                    card =
                                        _EmergencyRequestCard(
                                      requestId:
                                          request.requestId,
                                      data:
                                          request.data,
                                    );
                                    break;

                                  case _RequestType.food:
                                    card =
                                        _FoodRequestCard(
                                      requestId:
                                          request.requestId,
                                      data:
                                          request.data,
                                    );
                                    break;

                                  case _RequestType.medicine:
                                    card =
                                        _MedicineRequestCard(
                                      requestId:
                                          request.requestId,
                                      data:
                                          request.data,
                                    );
                                    break;

                                  case _RequestType.rescue:
                                    card =
                                        _RescueRequestCard(
                                      requestId:
                                          request.requestId,
                                      data:
                                          request.data,
                                    );
                                    break;
                                }

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      card,
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _confirmAndDeleteRequest(context, request),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Color(0xFFDC2626),
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'DELETE REQUEST',
                                            style: TextStyle(
                                              color: Color(0xFFDC2626),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDeleteRequest(
    BuildContext context,
    _RequestItem request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text(
          'This request will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final collection = switch (request.type) {
      _RequestType.emergency => 'emergency_sos',
      _RequestType.food => 'food_requests',
      _RequestType.medicine => 'medicine_requests',
      _RequestType.rescue => 'rescue_requests',
    };

    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(request.requestId)
          .delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'You are not allowed to delete this request. Check Firestore rules.'
                : 'Unable to delete request. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete request. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(int requestCount) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF087F8C),
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Your Requests',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  requestCount == 1
                      ? '1 request submitted'
                      : '$requestCount requests submitted',

                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
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
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Unable to load your requests.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 80,
              height: 80,

              decoration:
                  const BoxDecoration(
                color: Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.inbox_outlined,
                size: 42,
                color: Color(0xFF087F8C),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No Requests Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102A43),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your submitted requests will appear here.',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// REQUEST TYPE
// ================================================================

enum _RequestType {
  emergency,
  food,
  medicine,
  rescue,
}

// ================================================================
// REQUEST ITEM
// ================================================================

class _RequestItem {
  final String requestId;
  final _RequestType type;
  final Map<String, dynamic> data;

  const _RequestItem({
    required this.requestId,
    required this.type,
    required this.data,
  });
}

// ================================================================
// EMERGENCY REQUEST CARD
// ================================================================

class _EmergencyRequestCard
    extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const _EmergencyRequestCard({
    required this.requestId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final emergencyType =
        data['emergencyType']?.toString() ??
            'Emergency';

    final description =
        data['description']?.toString() ?? '';

    final status =
        data['status']?.toString() ?? 'received';

    final severity =
        data['severity']?.toString() ?? 'Normal';

    final assignedDepartment =
        data['assignedDepartment']?.toString() ??
            'Not assigned';

    final priorityData =
        data['priority'];

    String priorityLevel =
        severity;

    int? priorityScore;

    if (priorityData is Map) {
      priorityLevel =
          priorityData['level']?.toString() ??
              severity;

      final score =
          priorityData['score'];

      if (score is int) {
        priorityScore = score;
      } else if (score != null) {
        priorityScore =
            int.tryParse(
          score.toString(),
        );
      }
    }

    final createdAt =
        data['createdAt'] as Timestamp?;

    final affectedPerson =
        data['affectedPerson'];

    String affectedText =
        'Not specified';

    if (affectedPerson is Map) {
      final type =
          affectedPerson['type']?.toString();

      final name =
          affectedPerson['name']?.toString();

      if (type == 'citizen') {
        affectedText = 'Myself';
      } else if (type ==
              'family_member' &&
          name != null &&
          name.isNotEmpty) {
        affectedText = name;
      } else if (type ==
          'entire_family') {
        affectedText =
            'Entire Family';
      } else if (type == 'none') {
        affectedText = 'None';
      }
    }

    final photoAttached =
        data['photoAttached'] == true;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFEEEE),
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.emergency_rounded,
                  color:
                      Color(0xFFEF4444),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        const Text(
                          'Emergency SOS',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Color(0xFF102A43),
                          ),
                        ),

                        const SizedBox(width: 7),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 7,
                            vertical: 3,
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
                              10,
                            ),
                          ),

                          child:
                              const Text(
                            'SOS',
                            style:
                                TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                                  Color(
                                0xFFEF4444,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      createdAt == null
                          ? 'Date unavailable'
                          : _formatDate(
                              createdAt.toDate(),
                            ),

                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                          0xFF64748B,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _PriorityBadge(
                level:
                    priorityLevel,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            emergencyType,
            style:
                const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF334155),
            ),
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),

            Text(
              description,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontSize: 14,
                color:
                    Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 14),

          _InfoRow(
            icon:
                Icons.person_outline_rounded,
            label: 'Affected',
            value:
                affectedText,
          ),

          const SizedBox(height: 9),

          _InfoRow(
            icon:
                Icons.account_balance_outlined,
            label: 'Department',
            value:
                assignedDepartment,
          ),

          if (priorityScore != null) ...[
            const SizedBox(height: 9),

            _InfoRow(
              icon:
                  Icons.analytics_outlined,
              label:
                  'Priority Score',
              value:
                  priorityScore.toString(),
            ),
          ],

          if (photoAttached) ...[
            const SizedBox(height: 9),

            const _InfoRow(
              icon:
                  Icons.photo_camera_outlined,
              label: 'Photo',
              value: 'Attached',
            ),
          ],

          const SizedBox(height: 16),

          const Divider(
            height: 1,
            color:
                Color(0xFFE2E8F0),
          ),

          const SizedBox(height: 14),

          _StatusSection(
            status: status,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// FOOD REQUEST CARD
// ================================================================

class _FoodRequestCard
    extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const _FoodRequestCard({
    required this.requestId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final foodType =
        data['foodType']?.toString() ??
            'Food Request';

    final quantity =
        data['quantity'];

    final peopleCount =
        data['peopleCount'];

    final description =
        data['description']?.toString() ?? '';

    final status =
        data['status']?.toString() ??
            'received';

    final createdAt =
        data['createdAt'] as Timestamp?;

    String quantityText = '';

    if (quantity != null) {
      quantityText =
          quantity.toString();
    }

    String peopleText = '';

    if (peopleCount != null) {
      peopleText =
          peopleCount.toString();
    }

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFF6DE),
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.restaurant_rounded,
                  color:
                      Color(0xFFF2A900),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        const Text(
                          'Food Request',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Color(0xFF102A43),
                          ),
                        ),

                        const SizedBox(width: 7),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFFFF6DE,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),

                          child:
                              const Text(
                            'FOOD',
                            style:
                                TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                                  Color(
                                0xFFB77900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      createdAt == null
                          ? 'Date unavailable'
                          : _formatDate(
                              createdAt.toDate(),
                            ),

                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                          0xFF64748B,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            foodType,
            style:
                const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: _FoodInfoBox(
                  icon:
                      Icons.inventory_2_outlined,
                  label: 'Quantity',
                  value:
                      quantityText.isEmpty
                          ? 'Not specified'
                          : '$quantityText portions',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _FoodInfoBox(
                  icon:
                      Icons.people_alt_outlined,
                  label: 'People',
                  value:
                      peopleText.isEmpty
                          ? 'Not specified'
                          : '$peopleText people',
                ),
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),

            _InfoRow(
              icon:
                  Icons.description_outlined,
              label: 'Details',
              value:
                  description,
            ),
          ],

          const SizedBox(height: 16),

          const Divider(
            height: 1,
            color:
                Color(0xFFE2E8F0),
          ),

          const SizedBox(height: 14),

          _StatusSection(
            status: status,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MEDICINE REQUEST CARD
// ================================================================

class _MedicineRequestCard
    extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const _MedicineRequestCard({
    required this.requestId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final medicine =
        data['medicine']?.toString() ??
            'Medicine Request';

    final condition =
        data['condition']?.toString() ??
            'Not specified';

    final details =
        data['details']?.toString() ?? '';

    final status =
        data['status']?.toString() ??
            'received';

    final createdAt =
        data['createdAt'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFEEEE),

                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.medication_rounded,
                  color:
                      Color(0xFFEF4444),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        const Text(
                          'Medicine Request',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Color(0xFF102A43),
                          ),
                        ),

                        const SizedBox(width: 7),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 7,
                            vertical: 3,
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
                              10,
                            ),
                          ),

                          child:
                              const Text(
                            'MEDICINE',
                            style:
                                TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                                  Color(
                                0xFFBE123C,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      createdAt == null
                          ? 'Date unavailable'
                          : _formatDate(
                              createdAt.toDate(),
                            ),

                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                          0xFF64748B,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _InfoRow(
            icon:
                Icons.medication_outlined,
            label: 'Medicine',
            value:
                medicine,
          ),

          const SizedBox(height: 10),

          _InfoRow(
            icon:
                Icons.healing_outlined,
            label: 'Condition',
            value:
                condition,
          ),

          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),

            _InfoRow(
              icon:
                  Icons.description_outlined,
              label: 'Details',
              value:
                  details,
            ),
          ],

          const SizedBox(height: 16),

          const Divider(
            height: 1,
            color:
                Color(0xFFE2E8F0),
          ),

          const SizedBox(height: 14),

          _StatusSection(
            status: status,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// RESCUE REQUEST CARD
// ================================================================

class _RescueRequestCard
    extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const _RescueRequestCard({
    required this.requestId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final rescueType =
        data['rescueType']?.toString() ??
            'Rescue Request';

    final details =
        data['details']?.toString() ?? '';

    final status =
        data['status']?.toString() ??
            'received';

    final createdAt =
        data['createdAt'] as Timestamp?;

    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border:
            Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ========================================================
          // TOP ROW
          // ========================================================

          Row(
            children: [
              Container(
                width:
                    44,
                height:
                    44,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFE9F6FF),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child:
                    const Icon(
                  Icons
                      .directions_boat_rounded,
                  color:
                      Color(0xFF2196F3),
                ),
              ),

              const SizedBox(
                width:
                    12,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Row(
                      children: [
                        const Text(
                          'Rescue Request',
                          style:
                              TextStyle(
                            fontSize:
                                17,
                            fontWeight:
                                FontWeight
                                    .w800,
                            color:
                                Color(
                              0xFF102A43,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width:
                              7,
                        ),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                7,
                            vertical:
                                3,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFE9F6FF,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),

                          child:
                              const Text(
                            'RESCUE',
                            style:
                                TextStyle(
                              fontSize:
                                  9,
                              fontWeight:
                                  FontWeight
                                      .w900,
                              color:
                                  Color(
                                0xFF1565C0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          3,
                    ),

                    Text(
                      createdAt == null
                          ? 'Date unavailable'
                          : _formatDate(
                              createdAt
                                  .toDate(),
                            ),

                      style:
                          const TextStyle(
                        fontSize:
                            12,
                        color:
                            Color(
                          0xFF64748B,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                16,
          ),

          // ========================================================
          // RESCUE TYPE
          // ========================================================

          _InfoRow(
            icon:
                Icons
                    .emergency_share_outlined,
            label:
                'Rescue Type',
            value:
                rescueType,
          ),

          // ========================================================
          // DETAILS
          // ========================================================

          if (details.isNotEmpty) ...[
            const SizedBox(
              height:
                  10,
            ),

            _InfoRow(
              icon:
                  Icons
                      .description_outlined,
              label:
                  'Details',
              value:
                  details,
            ),
          ],

          const SizedBox(
            height:
                16,
          ),

          const Divider(
            height:
                1,
            color:
                Color(0xFFE2E8F0),
          ),

          const SizedBox(
            height:
                14,
          ),

          // ========================================================
          // STATUS
          // ========================================================

          _StatusSection(
            status:
                status,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// FOOD INFO BOX
// ================================================================

class _FoodInfoBox
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FoodInfoBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(12),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF5F7FA),
        borderRadius:
            BorderRadius.circular(13),
      ),

      child:
          Row(
        children: [
          Icon(
            icon,
            size:
                19,
            color:
                const Color(0xFF087F8C),
          ),

          const SizedBox(
            width:
                8,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    fontSize:
                        10,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(
                      0xFF64748B,
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(
                  value,
                  maxLines:
                      2,
                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(
                      0xFF334155,
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
}

// ================================================================
// STATUS SECTION
// ================================================================

class _StatusSection
    extends StatelessWidget {
  final String status;

  const _StatusSection({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Current Status',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF475569),
          ),
        ),

        const Spacer(),

        _StatusBadge(
          status:
              status,
        ),
      ],
    );
  }
}

// ================================================================
// PRIORITY BADGE
// ================================================================

class _PriorityBadge
    extends StatelessWidget {
  final String level;

  const _PriorityBadge({
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final normalized =
        level.toLowerCase();

    Color background;
    Color foreground;

    if (normalized ==
        'critical') {
      background =
          const Color(0xFFFFE4E6);
      foreground =
          const Color(0xFFBE123C);
    } else if (normalized ==
        'high') {
      background =
          const Color(0xFFFFF7ED);
      foreground =
          const Color(0xFFC2410C);
    } else {
      background =
          const Color(0xFFFEFCE8);
      foreground =
          const Color(0xFFA16207);
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            10,
        vertical:
            6,
      ),

      decoration:
          BoxDecoration(
        color:
            background,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Text(
        level.toUpperCase(),

        style:
            TextStyle(
          fontSize:
              10,
          fontWeight:
              FontWeight.w900,
          color:
              foreground,
        ),
      ),
    );
  }
}

// ================================================================
// STATUS BADGE
// ================================================================

class _StatusBadge
    extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized =
        status.toLowerCase();

    Color background;
    Color foreground;
    String displayText;

    switch (normalized) {
      case 'received':
      case 'submitted':
        background =
            const Color(0xFFEFF6FF);
        foreground =
            const Color(0xFF1D4ED8);
        displayText =
            'RECEIVED';
        break;

      case 'verified':
        background =
            const Color(0xFFF0FDFA);
        foreground =
            const Color(0xFF0F766E);
        displayText =
            'VERIFIED';
        break;

      case 'assigned':
        background =
            const Color(0xFFF5F3FF);
        foreground =
            const Color(0xFF6D28D9);
        displayText =
            'ASSIGNED';
        break;

      case 'in_progress':
      case 'in progress':
        background =
            const Color(0xFFFFF7ED);
        foreground =
            const Color(0xFFC2410C);
        displayText =
            'IN PROGRESS';
        break;

      case 'resolved':
      case 'completed':
        background =
            const Color(0xFFECFDF5);
        foreground =
            const Color(0xFF047857);
        displayText =
            'RESOLVED';
        break;

      case 'rejected':
        background =
            const Color(0xFFFFE4E6);
        foreground =
            const Color(0xFFBE123C);
        displayText =
            'REJECTED';
        break;

      default:
        background =
            const Color(0xFFF1F5F9);
        foreground =
            const Color(0xFF475569);
        displayText =
            status.toUpperCase();
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            12,
        vertical:
            7,
      ),

      decoration:
          BoxDecoration(
        color:
            background,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Text(
        displayText,

        style:
            TextStyle(
          fontSize:
              11,
          fontWeight:
              FontWeight.w900,
          color:
              foreground,
        ),
      ),
    );
  }
}

// ================================================================
// INFO ROW
// ================================================================

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size:
              19,
          color:
              const Color(0xFF087F8C),
        ),

        const SizedBox(
          width:
              9,
        ),

        Text(
          '$label: ',

          style:
              const TextStyle(
            fontSize:
                13,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF64748B),
          ),
        ),

        Expanded(
          child:
              Text(
            value,
            maxLines:
                3,
            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              fontSize:
                  13,
              color:
                  Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// DATE FORMATTER
// ================================================================

String _formatDate(
  DateTime date,
) {
  final day =
      date.day.toString().padLeft(
        2,
        '0',
      );

  final month =
      date.month.toString().padLeft(
        2,
        '0',
      );

  final year =
      date.year.toString();

  final hour =
      date.hour.toString().padLeft(
        2,
        '0',
      );

  final minute =
      date.minute.toString().padLeft(
        2,
        '0',
      );

  return '$day/$month/$year  $hour:$minute';
}